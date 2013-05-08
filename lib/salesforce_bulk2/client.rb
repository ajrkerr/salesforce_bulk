# client.rb
# Author: Adam Kerr <adam.kerr@zucora.com>
# Date:   May 7th, 2013
# Description: The connection and base interface for the Salesforce Bulk API

module SalesforceBulk2
  # Interface for operating the Salesforce Bulk REST API
  class Client
    # If true, print API debugging information to stdout. Defaults to false.
    attr_accessor :debugging

    # The host to use for authentication. Defaults to login.salesforce.com.
    attr_reader :host

    # The instance host to use for API calls. Determined from login response.
    attr_reader :instance_host

    # The Salesforce password
    attr_reader :password

    # The Salesforce security token
    attr_reader :token

    # The Salesforce username
    attr_reader :username

    # The API version the client is using
    attr_reader :version

    #List of jobs associatd with this client
    attr_reader :jobs

    #Default batch size for any operation
    attr_reader :batch_size

    # Defaults
    @@login_host = 'login.salesforce.com'
    @@version = 27.0
    @@debugging = false
    @@api_path_prefix = "/services/async/"
    @@timeout = 2
    @@batch_size = 10000


    def initialize options
      if options.is_a?(String)
        options = YAML.load_file(options)
        options.symbolize_keys!
      end

      @username   = options[:username]
      @password   = "#{options[:password]}#{options[:token]}"
      @token      = options[:token]       || ''
      @login_host = options[:login_host]  || @@login_host
      @version    = options[:version]     || @@version
      @timeout    = options[:timeout]     || @@timeout
      @debugging  = options[:debugging]   || @@debugging
      @batch_size = options[:batch_size]  || @@batch_size

      @jobs = JobCollection.new
    end

    def connect options = {}
      raise Error.new("Already connected") if connected?

      @username = options[:username] || @username
      @password = options[:password] || @password
      @version  = options[:version] || @version

      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
      xml += ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
      xml += ' xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">'
      xml += '  <env:Body>'
      xml += '    <n1:login xmlns:n1="urn:partner.soap.sforce.com">'
      xml += "      <n1:username>#{@username}</n1:username>"
      xml += "      <n1:password>#{@password}</n1:password>"
      xml += "    </n1:login>"
      xml += "  </env:Body>"
      xml += "</env:Envelope>"

      data = http_post_xml("/services/Soap/u/#{@version}", xml, 'Content-Type' => 'text/xml', 'SOAPAction' => 'login')
      result = data['Body']['loginResponse']['result']

      @session_id = result['sessionId']
      @server_url = result['serverUrl']
      @instance_id = get_instance_id(@server_url)
      @instance_host = "#{@instance_id}.salesforce.com"
      @api_path_prefix = "#{@@api_path_prefix}/#{@version}/"

      result
    end

    def disconnect
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
      xml += ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
      xml += ' xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">'
      xml += '  <env:Body>'
      xml += '    <n1:logout xmlns:n1="urn:partner.soap.sforce.com" />'
      xml += '  </env:Body>'
      xml += '</env:Envelope>'

      result = http_post_xml("/services/Soap/u/#{@version}", xml, 'Content-Type' => 'text/xml', 'SOAPAction' => 'logout')

      @session_id = nil
      @server_url = nil
      @instance_id = nil
      @instance_host = nil
      @api_path_prefix = nil

      result
    end

    def connected?
      !!@session_id
    end

    def http_post(path, body, headers={})
      headers = {'Content-Type' => 'application/xml'}.merge(headers)

      if connected?
        #Set session ID and prefix the path for our request
        headers['X-SFDC-Session'] = @session_id
        host = @instance_host
        path = "#{@api_path_prefix}#{path}"
      else
        #We are trying to login, so don't set anything else
        host = @login_host
      end

      response = https_request(host).post(path, body, headers)
      verify_response(response)
    end

    def http_get(path, headers={})
      path = "#{@api_path_prefix}#{path}"

      headers = {'Content-Type' => 'application/xml'}.merge(headers)
      headers['X-SFDC-Session'] = @session_id if @session_id

      response = https_request(@instance_host).get(path, headers)
      verify_response(response)
    end

    def verify_response(response)
      if response.is_a?(Net::HTTPSuccess)
        response
      else
        raise SalesforceError.new(response)
      end
    end

    def http_post_xml(path, body, headers = {})
      XmlSimple.xml_in(http_post(path, body, headers).body, :ForceArray => false)
    end

    def http_get_xml(path, headers = {})
      XmlSimple.xml_in(http_get(path, headers).body, :ForceArray => false)
    end

    def https_request(host)
      req = Net::HTTP.new(host, 443)
      req.use_ssl = true
      req.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req
    end

    

    #Job related
    def create_job options = {}
      job = Job.create(self, options)
      @jobs << job

      return job
    end

    def find_job id
      return Job.find(self, id)
    end

    def close_jobs
      @jobs.close
      return @jobs
    end

    def abort_jobs
      @jobs.abort
      return @jobs
    end


    ## Operations
    def delete(sobject, data, options = {})
      perform_operation(:delete, sobject, data, options)
    end

    def insert(sobject, data, options = {})
      perform_operation(:insert, sobject, data, options)
    end

    def query(sobject, data, options = {})
      perform_operation(:query, sobject, data, options)
    end

    def update(sobject, data, options = {})
      perform_operation(:update, sobject, data, options)
    end

    def upsert(sobject, data, external_id, options = {})
      options.merge!(external_id: external_id)

      perform_operation(:upsert, sobject, data, options)
    end

    def perform_operation(operation, sobject, data, options = {})
      {
        operation: operation,
        object: sobject,
      }.merge(options)

      job = Job.new(self, options)
      (operation: operation, object: sobject, external_id: options[:external_id])

      batch_size = options[:batch_size] || self.batch_size

      job.add_data(data)
      job.close

      until job.finished?
        job.refresh
        sleep @timeout
      end

      return job.get_results
    end

  private
    def get_instance_id(url)
      url.match(/:\/\/([a-zA-Z0-9-]{2,}).salesforce/)[1]
    end
  end
end