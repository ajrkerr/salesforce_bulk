##
# This class provides an interface to interact with bulk jobs in Salesforce.
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  class Job
    attr_reader :client
    attr_reader :operation        # Operation  of job
    attr_reader :concurrency_mode # Concurrency mode
    attr_reader :external_id      # External ID for Upserts
    attr_reader :content_type     # Content type, defaults to :xml
    attr_reader :sobject          # sObject that we are working with
    attr_reader :batch_size       # Default batch size

    ##
    # Lists to validate different configuration options
    @@valid_operations = [:delete, :insert, :update, :upsert, :query]
    @@valid_concurrency_modes = ['Parallel', 'Serial']
    @@valid_content_types = [:xml, :csv]
    @@max_batch_size = 10000

    ##
    # Creates a new job from a salesforce client and JobInfo object
    def initialize client, job_info, options = {}
      @client = client
      @job_info = job_info

      @sobject = options[:sobject]
      @operation = options[:operation].to_sym.downcase if options[:operation]
      @external_id = options[:external_id]
      @content_type = options[:content_type]
      @concurrency_mode = options[:concurrency_mode]
      @batch_size = options[:batch_size] || @client.batch_size || @@max_batch_size
    end

    ##
    # Verify an operation is valid
    def self.valid_operation? operation
      @@valid_operations.include?(operation)
    end

    ##
    # Verify a concurrency mode is valid
    def self.valid_concurrency_mode? mode
      @@valid_concurrency_modes.include?(concurrency_mode)
    end

    ##
    # Creates a new job object
    def self.create client, options = {}
      sobject = options[:sobject]
      operation = options[:operation].to_sym.downcase
      external_id = options[:external_id]
      content_type = options[:content_type]
      concurrency_mode = options[:concurrency_mode]

      # Verify the operation is valid
      if !Job.valid_operation?(operation)
        raise ArgumentError.new("Invalid operation: #{operation}") 
      end

      # Verify the concurrency mode is valid
      if concurrency_mode and !Job.valid_concurrency_mode?(concurrency_mode)
        raise ArgumentError.new("Invalid concurrency mode: #{concurrency_mode}")
      end

      # Verify the content type is valid
      if !Job.valid_content_type?(content_type)
        raise ArgumentError.new("Invalid content type: #{content_type}")
      end

      #Construct XML request
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'
      xml += "  <operation>#{operation}</operation>"
      xml += "  <object>#{sobject}</object>" if sobject
      xml += "  <externalIdFieldName>#{external_id}</externalIdFieldName>" if external_id
      xml += "  <concurrencyMode>#{concurrency_mode}</concurrencyMode>" if concurrency_mode
      xml += "  <contentType>CSV</contentType>" if content_type == :csv
      xml += "  <contentType>XML</contentType>" if content_type == :xml
      xml += "</jobInfo>"

      job_info = Envelopes::Envelopes::JobInfo.new client.http_post_xml("job", xml)
      
      return Job.new(client, job_info, options)
    end

    ##
    # Creates a new batch in the current job
    def create_batch data
      raise Exception.new "Job is closed.  We cannot create new batches." unless can_create_batches?

      #Check the content type and set the HTTP header accordingly
      if content_type == :xml
        content_type_header = "application/xml; charset=UTF-8"
      elsif content_type == :csv
        content_type_header = "text/csv; charset=UTF-8"
      else
        raise ArgumentError, "Content Type is invalid.  Must be either csv or xml."
      end

      # Verify our batch size isn't too big
      raise ArgumentError, "Batch size #{self.batch_size} exceeds the maximum of #{max_batch_size}" if batch_size > @max_batch_size
      
      # See if we need to compact the data ourselves
      if data.is_a?(Array)
        # Validate array size
        raise ArgumentError, "Batch data set exceeds #{self.batch_size} record limit by #{data.length - self.batch_size} record(s)" if data.length > self.batch_size
        raise ArgumentError, "Batch data set is empty" if data.length < 1
        
        body = parse_data_array(data)
      else
        # Assume we've been sent text that can be sent
        body = data
      end

      @client.http_post_xml("job/#{@job_id}/batch", body, "Content-Type" => content_type_header)
    end

    ##
    # Parses data according to the content type
    def parse_data_array data
      case content_type
      when :xml
        #TODO write XML portion
        XmlSimple.xml_out(data)
      when :csv
        # Process array into a CSV format
        parsed_data = ''

        # Use the first row as the header records
        header_row = data.first.keys
        parsed_data += header_row.to_csv
        
        data.each do |item|
          item_values = header_row.map { |key| item[key] }
          parsed_data += item_values.to_csv
        end
      else
        parsed_data = data
      end

      return parsed_data
    end

    ##
    # Finds a job
    def self.find client, id
      job = Job.new(client)
      job.id = id
      job.refresh

      return job
    end

    ##
    # Locates a specific batch belonging to this job
    def find_batch batch_id
      return Batch.find(job, batch_id)
    end

    ##    
    # Updates this job from the server
    def refresh
      @job_info = Envelopes::JobInfo.new(@client.http_get_xml("job/#{@id}"))
    end

    ##
    # Reloads all batches from Salesforce
    def reload_batches
      batches_xml = @client.http_get_xml("job/#{@id}/batch")

      # Empty our collection of batches
      @batches.clear

      Array(batches_xml).each do |xml|
        @batches << Batch.new(self, xml)
      end

      return @batches
    end

    ## 
    # Refresh the current list of batches
    def refresh_batches
      @batches.refresh
    end

    ##
    # Abort the current job
    def abort
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'
      xml += '  <state>Aborted</state>'
      xml += '</jobInfo>'

      @job_info = Envelopes::JobInfo.new @client.http_post_xml("job/#{@id}", xml)
    end

    ##
    # Close the current job
    def close
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'
      xml += '  <state>Closed</state>'
      xml += '</jobInfo>'

      @job_info = Envelopes::JobInfo.new @client.http_post_xml("job/#{@id}", xml)
    end

    ##
    # Add data to the current job
    def add_data data, batch_size = nil
      batch_size ||= @batch_size

      data.each_slice(batch_size) do |records|
        create_batch(records)
      end
    end

    ##
    # Retrieve and process the results from all batches
    def get_results
      @batches.get_results
    end

    ##
    # Retrieve all original requests from the batches
    def get_requests
      @batches.get_requests
    end


    ### Status Helpers ###
    # These helpers provide quick accessors to check the status of the job
    # Refer to the official Salesforce documentation for the meaning and
    # progression of job statuses

    ##
    # True if all batches have finished processing
    def batches_finished?
      (@number_batches_queued == 0) and
      (@number_batches_in_progress == 0)
    end

    ##
    # True if the job is done running
    def finished?
      failed?  or
      aborted? or
      (closed? and batches_finished?)
    end

    ##
    # True if the job failed
    def failed?
      state? 'Failed'
    end

    ##
    # True if the job was aborted
    def aborted?
      state? 'Aborted'
    end

    ##
    # True if the job has been closed
    def closed?
      state? 'Closed'
    end

    ##
    # True if the job is open and not yet closed
    def open?
      state? 'Open'
    end

    ##
    # True if we can still create new batches for this job
    def can_create_batches?
      open?
    end

    ##
    # True if job finished successfully
    def successful?
      closed? and finished? and numberBatchesFailed == 0
    end

    ##
    # Returns true if the argument matches the present state
    def state? value
      @state.present? && @state.casecmp(value) == 0
    end

    
    ### Delegate extra methods to JobInfo ###

    ##
    # Delegate methods to job_info
    def method_missing method, *args, &block
      @job_info.send(method, *args, &block) or
      super
    end

    ##
    # Ensure that we report we can respond to these methods
    def respond_to? method, include_all = false
      @job_info.respond_to?(method, include_all) or
      super
    end
  end
end
