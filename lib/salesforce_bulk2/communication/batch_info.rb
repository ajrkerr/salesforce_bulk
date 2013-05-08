module SalesforceBulk2
  #All Salesforce specific communication items
  module Communications
    class BatchInfo
      attr_reader :id
      attr_reader :job_id
      attr_reader :state_message
      attr_reader :created_date
      attr_reader :system_modstamp
      attr_reader :number_records_processed
      attr_reader :number_records_failed
      attr_reader :total_processing_time
      attr_reader :api_active_processing_time
      attr_reader :apex_processing_time

      def initialize data
        @id = data['id']
        @job_id = data['jobId']
        @state_message = data['stateMessage']
        @created_date = DateTime.parse(data['createdDate']) rescue nil
        @system_modstamp = DateTime.parse(data['systemModstamp']) rescue nil
        @number_records_processed = data['numberRecordsProcessed'].to_i
        @number_records_failed = data['numberRecordsFailed'].to_i
        @total_processing_time = data['totalProcessingTime'].to_i
        @api_active_processing_time = data['apiActiveProcessingTime'].to_i
        @apex_processing_time = data['apexProcessingTime'].to_i
      end

      def self.find batch
        batch_id = batch.id
        job_id = batch.job_id
        client = batch.client

        BatchInfo.new(client.http_get_xml("job/#{job_id}/batch/#{batch_id}"))
      end
    end
  end
end
