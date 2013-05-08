# job.rb
# Author: Adam Kerr <adam.kerr@zucora.com>
# Date:   May 7th, 2013
# Description: A data object to keep track of bulk jobs in Salesforce

module SalesforceBulk2
  class Job
    attr_reader :client

    attr_reader :concurrency_mode
    attr_reader :external_id
    attr_reader :data
    attr_reader :xml_data
    attr_reader :content_type

    attr_accessor :id

    @@fields = [:id, :operation, :object, :createdById, :state, :createdDate,
      :systemModstamp, :externalIdFieldName, :concurrencyMode, :contentType,
      :numberBatchesQueued, :numberBatchesInProgress, :numberBatchesCompleted,
      :numberBatchesFailed, :totalBatches, :retries, :numberRecordsProcessed,
      :numberRecordsFailed, :totalProcessingTime, :apiActiveProcessingTime,
      :apexProcessingTime, :apiVersion]

    @@valid_operations = [:delete, :insert, :update, :upsert, :query]
    @@valid_concurrency_modes = ['Parallel', 'Serial']
    @@valid_content_types = [:xml, :csv]

    @@fields.each do |field|
      attr_reader field.to_s.underscore.to_sym
    end

    def initialize client
      @client = client
    end

    def self.valid_operation? operation
      @@valid_operations.include?(operation)
    end

    def self.valid_concurrency_mode? mode
      @@valid_concurrency_modes.include?(concurrency_mode)
    end

    def self.create client, options = {}
      job = Job.new(client)

      object = options[:object]
      operation = options[:operation].to_sym.downcase
      external_id = options[:external_id]
      content_type = options[:content_type]
      concurrency_mode = options[:concurrency_mode]

      if !Job.valid_operation?(operation)
        raise ArgumentError.new("Invalid operation: #{operation}") 
      end

      if concurrency_mode and !Job.valid_concurrency_mode?(concurrency_mode)
        raise ArgumentError.new("Invalid concurrency mode: #{concurrency_mode}")
      end

      if !Job.valid_content_type?(content_type)
        raise ArgumentError.new("Invalid content type: #{content_type}")
      end

      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'
      xml += "  <operation>#{operation}</operation>"
      xml += "  <object>#{object}</object>" if object
      xml += "  <externalIdFieldName>#{external_id}</externalIdFieldName>" if external_id
      xml += "  <concurrencyMode>#{concurrency_mode}</concurrencyMode>" if concurrency_mode
      xml += "  <contentType>CSV</contentType>" if content_type == :csv
      xml += "  <contentType>XML</contentType>" if content_type == :xml
      xml += "</jobInfo>"

      job.update(client.http_post_xml("job", xml))
      
      return job
    end

    def create_batch data
      raise Exception.new "Already executed" if executed?

      @original_data = data
      @content_type = content_type

      if @job.content_type == :xml
        content_type_header = "text/xml; charset=UTF-8"
      elsif @job.content_type == :csv
        content_type_header = "text/csv; charset=UTF-8"
      else
        raise ArgumentError, "Content Type is invalid.  Must be either csv or xml."
      end
      
      #See if we need to compact the data ourselves
      if data.is_a?(Array)
        raise ArgumentError, "Batch data set exceeds #{self.batch_size} record limit by #{data.length - self.batch_size} record(s)" if data.length > self.batch_size
        raise ArgumentError, "Batch data set is empty" if data.length < 1
        
        keys = data.first.keys
        body = keys.to_csv
        
        data.each do |item|
          item_values = keys.map { |key| item[key] }
          body += item_values.to_csv
        end
      else 
        body = data
      end

      # Despite the content for a query operation batch being plain text we 
      # still have to specify CSV content type per API docs.
      @client.http_post_xml("job/#{@job_id}/batch", body, "Content-Type" => content_type_header)
    end

    def self.find client, id
      job = Job.new(client)
      job.id = id
      job.refresh

      return job
    end

    def find_batch batch_id
      batch = Batch.new(job)
      batch.id = batch_id
      batch.refresh

      return batch
    end

    def refresh
      update @client.http_get_xml("job/#{@id}")
    end

    def refresh_batches
      batches_xml = @client.http_get_xml("job/#{@id}/batch")
      @batches.clear

      Array(batches_xml).each do |xml|
        @batches << Batch.new(self, xml)
      end

      return @batches
    end

    def abort
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'
      xml += '  <state>Aborted</state>'
      xml += '</jobInfo>'

      @client.http_post_xml("job/#{@id}", xml)
    end

    def close
      xml  = '<?xml version="1.0" encoding="utf-8"?>'
      xml += '<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">'
      xml += '  <state>Closed</state>'
      xml += '</jobInfo>'

      @client.http_post_xml("job/#{@id}", xml)
    end

    def add_data data, batch_size = nil
      raise JobError.new("Job is not open for adding more data")) if !open?
      
      batch_size ||= @client.batch_size

      data.each_slice(batch_size) do |records|
        batch = Batch.new(self)
        batch.add(records)
        @batches << batch
      end
    end

    def get_results
      results = BatchResultCollection.new
      @batches.each { |batch| results << batch.get_result }
      results.flatten
    end

    # def get_requests
    #   results = BatchResultCollection.new

    #   get_batches.each { |batch| results << batch.get_request }

    #   results.flatten
    # end


    #Status Helpers
    def batches_finished?
      (@number_batches_queued == 0) and
      (@number_batches_in_progress == 0)
    end

    def finished?
      failed?  or
      aborted? or
      (closed? and batches_finished?)
    end

    def failed?
      state? 'Failed'
    end

    def aborted?
      state? 'Aborted'
    end

    def closed?
      state? 'Closed' || failed? || aborted?
    end

    def open?
      state? 'Open'
    end

    def state?(value)
      @state.present? && @state.casecmp(value) == 0
    end

  private
    def update xml_data
      #Assign object
      @xml_data = xml_data

      #Mass assign the defaults
      @@fields.each do |field|
        instance_variable_set(:"@#{field}", xml_data[field.to_s])
      end

      #Special cases and data formats
      @created_date = DateTime.parse(xml_data['createdDate'])
      @system_modstamp = DateTime.parse(xml_data['systemModstamp'])

      @retries = xml_data['retries'].to_i
      @api_version = xml_data['apiVersion'].to_i
      @number_batches_queued = xml_data['numberBatchesQueued'].to_i
      @number_batches_in_progress = xml_data['numberBatchesInProgress'].to_i
      @number_batches_completed = xml_data['numberBatchesCompleted'].to_i
      @number_batches_failed = xml_data['numberBatchesFailed'].to_i
      @total_batches = xml_data['totalBatches'].to_i
      @number_records_processed = xml_data['numberRecordsProcessed'].to_i
      @number_records_failed = xml_data['numberRecordsFailed'].to_i
      @total_processing_time = xml_data['totalProcessingTime'].to_i
      @api_active_processing_time = xml_data['apiActiveProcessingTime'].to_i
      @apex_processing_time = xml_data['apexProcessingTime'].to_i
    end
  end
end
