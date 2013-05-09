##
# The connection and base interface for the Salesforce Bulk API
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  # Interface for operating the Salesforce Bulk REST API
  class Client
    # If true, print API debugging information to stdout. Defaults to false.
    attr_accessor :debugging

    # The host to use for authentication. Defaults to login.salesforce.com.
    attr_reader :login_host

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

    # List of jobs associatd with this client
    attr_reader :jobs

    # Default batch size for any operation
    attr_reader :batch_size

    # Whether to use SSL for our HTTP requests
    attr_reader :enable_ssl

    # Whether to force verification of the server certificate
    attr_reader :verify_certificate

    # HTTP header when sending requests to Salesforce
    attr_reader :header

    # Defaults
    @@login_host = 'login.salesforce.com'
    @@version = 27.0
    @@debugging = false
    @@api_path_prefix = "/services/async/"
    @@timeout = 2
    @@batch_size = 10000
    @@enable_ssl = true
    @@verify_certificate = false
    @@port = 443
    @@header = {
      'Content-Type' => 'application/xml'
    }


    ##
    # Creates a new client
    def initialize options
      # Pull options from a Yaml file if specified
      if options.is_a?(String)
        options = YAML.load_file(options)
        options.symbolize_keys!
      end

      #Verify username and password are sent
      raise ArgumentError.new("Invalid Username: A username must be specified") unless options[:username]
      raise ArgumentError.new("Invalid Password: A password must be specified") unless options[:password]

      # Set default options and configuration
      @username   = options[:username]
      @password   = "#{options[:password]}#{options[:token]}"
      @token      = options[:token]       || ''
      @login_host = options[:login_host]  || @@login_host
      @version    = options[:version]     || @@version
      @timeout    = options[:timeout]     || @@timeout
      @debugging  = options[:debugging]   || @@debugging
      @batch_size = options[:batch_size]  || @@batch_size
      @port       = options[:port]        || @@port
      @enable_ssl = options[:enable_ssl]  || @@enable_ssl
      @verify_certificate = options[:verify_certificate] || @@verify_certificate
      @default_header = @@header.merge(options[:header] || {})

      # List of all created jobs
      @jobs = JobCollection.new
    end

    def connect options = {}
      raise Error.new("Already connected") if connected?

      ## Allows 
      @username = options[:username] || @username
      @password = options[:password] || @password
      @version  = options[:version] || @version

      # Construct SOAP login request
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

      # Send Soap Login Request
      data = http_login_post("/services/Soap/u/#{@version}", xml, 'SOAPAction' => 'login')

      # Parse the result and extract session inforamtion
      result = data['Body']['loginResponse']['result']

      @session_id = result['sessionId']
      @server_url = result['serverUrl']
      @instance_id = get_instance_id(@server_url)
      @instance_host = "#{@instance_id}.salesforce.com"
      @api_path_prefix = "#{@@api_path_prefix}/#{@version}/"

      result
    end

    ##
    # Disconnects session from Salesforce
    def disconnect
      #Construct SOAP logout request
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
      xml += ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
      xml += ' xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">'
      xml += '  <env:Body>'
      xml += '    <n1:logout xmlns:n1="urn:partner.soap.sforce.com" />'
      xml += '  </env:Body>'
      xml += '</env:Envelope>'

      # Send logoout request
      result = http_post_xml("/services/Soap/u/#{@version}", xml, 'SOAPAction' => 'logout')

      # Reset environment variables to prevent requests from 
      # being accidently sent using old information
      @session_id = nil
      @server_url = nil
      @instance_id = nil
      @instance_host = nil
      @api_path_prefix = nil

      result
    end

    ##
    # Returns true if we are/were conenected
    def connected?
      !!@session_id or !!@instance_host
    end

    ### HTTP methods ###

    ##
    # Sends a login request to Salesforce and returns a parsed response
    def http_login_post path, body, header_options = {}
      #Build header
      header = build_header(header_options)
      response = https_request(@login_host).post(path, body, header)

      # Check for errors
      verify_response(response)

      return XmlSimple.xml_in(response.body, :ForceArray => false)
    end

    ##
    # Generic HTTP POST request to Salesforce
    def http_post path, body, header_options = {}
      # Verify we are logged in first
      if !connected?
        raise NotLoggedInErorr "Please login before making any requests"
      end

      # Construct path and header
      path = build_path(path)
      header = build_header(header_options)
      response = https_request(@instance_host).post(path, body, header)

      # Check for errors
      verify_response(response)

      return response
    end

    ##
    # Generic HTTP GET request to Salesforce
    def http_get path, header_options = {}
      # Verify we are logged in first
      if !connected?
        raise NotLoggedInErorr "Please login before making any requests"
      end

      # Construct path and header
      path = build_path(path)
      header = build_header(header_options)
      response = https_request(@instance_host).get(path, header)

      # Check for errors
      verify_response(response)

      return response
    end

    ##
    # Send a GET request and parse the XML returned
    def http_post_xml path, body, header = {}
      result = http_post(path, body, header)
      XmlSimple.xml_in(result.body, :ForceArray => false)
    end

    ##
    # Send a POST request and parse the XML returned
    def http_get_xml path, header = {}
      result = http_get(path, header)
      XmlSimple.xml_in(result.body, :ForceArray => false)
    end


    ### Job Managment ###

    ##
    # Creats a new job
    def create_job options = {}
      job = Job.create(self, options)
      @jobs << job

      return job
    end

    ##
    # Finds a specific job via ID
    def find_job id
      return Job.find(self, id)
    end

    ##
    # Closes all jobs
    def close_jobs
      @jobs.close

      return @jobs
    end

    ## 
    # Aborts all current jobs
    def abort_jobs
      @jobs.abort

      return @jobs
    end

    ##
    # Clears list of jobs
    def clear_jobs
      @jobs.clear

      return @jobs
    end


    ### Salesforce Bulk API Operations ###

    ##
    # Delete objects
    def delete sobject, data, options = {}
      perform_operation(:delete, sobject, data, options)
    end

    ##
    # Insert objects
    def insert sobject, data, options = {}
      perform_operation(:insert, sobject, data, options)
    end

    ##
    # Update Objects
    def update sobject, data, options = {}
      perform_operation(:update, sobject, data, options)
    end

    ##
    # Upsert objects
    def upsert sobject, data, external_id, options = {}
      options.merge!(external_id: external_id)

      perform_operation(:upsert, sobject, data, options)
    end

    ##
    # Query for objects
    def query sobject, query, options = {}
      options.merge({
        operation: :query,
        object: sobject
      })

      job = Job.create(self, options)

      job.query(query)
      job.close

      until job.finished?
        job.refresh
        sleep @timeout
      end

      return job.get_results
    end

    ## 
    # Performs the operation specified
    def perform_operation operation, sobject, data, options = {}
      options.merge({
        operation: operation,
        object: sobject
      })

      job = Job.create(self, options)

      batch_size = options[:batch_size] || @batch_size

      job.add_data(data, batch_size)
      job.close

      # Keep refreshing until the job finishes
      until job.finished?
        job.refresh
        sleep @timeout
      end

      #Return the results
      return job.get_results
    end

  private
    ##
    # Returns the constructed path
    def bulid_path path
      "#{@api_path_prefix}#{path}"
    end

    ##
    # Returns the salesforce instance ID from a URL
    def get_instance_id url
      url.match(/:\/\/([a-zA-Z0-9-]{2,}).salesforce/)[1]
    end

    ##
    # Handler for HTTPS requests
    def https_request host
      req = Net::HTTP.new(host, @port)
      req.use_ssl = true if @enable_ssl
      req.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @verify_certificate
      req
    end

    ##
    # Builds the header portion of any HTTP request
    def build_header header_options = {}
      header = @default_header.merge(header_options)
      
      if connected?
        # Add the session ID if it exists
        header['X-SFDC-Session'] = @session_id 
      end

      return header
    end

    ##
    # Filters responses.  Throws an exception if there was a Salesforce Error
    def verify_response response
      if response.is_a? Net::HTTPSuccess
        # Verify we receieved a 200 status
        return true
      else
        # Return Salesforce error message
        raise SalesforceError.new(response)
      end
    end
  end
end