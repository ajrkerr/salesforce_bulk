##
# Models the BatchInfo object that Salesforce sends
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  module Envelopes
    class BatchInfo

      ##
      # All fields in BatchInfo
      attr_reader :apex_processing_time
      attr_reader :api_active_processing_time
      attr_reader :created_date
      attr_reader :id
      attr_reader :job_id
      attr_reader :number_records_failed
      attr_reader :number_records_processed
      attr_reader :state
      attr_reader :state_message
      attr_reader :system_modstamp
      attr_reader :total_processing_time

      # Original data
      attr_reader :xml_data

      ##
      # Create the object from the original XML data
      def initialize xml_data
        # Assign object
        @xml_data                   = xml_data

        # Map the standard values
        @id                         = xml_data['id']
        @job_id                     = xml_data['jobId']
        @state                      = xml_data['state']
        @state_message              = xml_data['stateMessage']

        @created_date               = DateTime.parse(xml_data['createdDate'])
        @system_modstamp            = DateTime.parse(xml_data['systemModstamp']) rescue nil
        
        @apex_processing_time       = xml_data['apexProcessingTime'].to_i
        @api_active_processing_time = xml_data['apiActiveProcessingTime'].to_i
        @number_records_failed      = xml_data['numberRecordsFailed'].to_i
        @number_records_processed   = xml_data['numberRecordsProcessed'].to_i
        @total_processing_time      = xml_data['totalProcessingTime'].to_i
      end
    end
  end
end
