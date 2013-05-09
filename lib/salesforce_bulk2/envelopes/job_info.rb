##
# Models the JobInfo object that Salesforce sends
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  module Envelopes
    class JobInfo
      ## 
      # All fields in JobInfo
      attr_reader :apex_processing_time
      attr_reader :api_active_processing_time
      attr_reader :api_version
      attr_reader :assignment_rule_id
      attr_reader :concurrency_mode
      attr_reader :content_type
      attr_reader :created_by_id
      attr_reader :created_date
      attr_reader :external_id_field_name
      attr_reader :id
      attr_reader :number_batches_completed
      attr_reader :number_batches_failed
      attr_reader :number_batches_in_progress
      attr_reader :number_batches_queued
      attr_reader :number_batches_total
      attr_reader :number_records_failed
      attr_reader :number_records_processed
      attr_reader :number_retries
      attr_reader :object
      attr_reader :operation
      attr_reader :state
      attr_reader :system_modstamp
      attr_reader :total_batches
      attr_reader :total_processing_time

      # Original data
      attr_reader :xml_data

      ##
      # Create the object from the original XML data
      def initialize xml_data
        #Assign object
        @xml_data                   = xml_data

        #Map the corresponding variables
        @assignment_rule_id         = xml_data['assignmentRuleId']
        @concurrency_mode           = xml_data['concurrencyMode']
        @content_type               = xml_data['contentType']
        @created_by_id              = xml_data['createdById']
        @external_id_field_name     = xml_data['externalIdFieldName']
        @id                         = xml_data['id']
        @object                     = xml_data['object']
        @operation                  = xml_data['operation']
        @state                      = xml_data['state']

        #Special data types and data formats
        @created_date               = DateTime.parse(xml_data['createdDate'])
        @system_modstamp            = DateTime.parse(xml_data['systemModstamp']) rescue nil

        @apex_processing_time       = xml_data['apexProcessingTime'].to_i
        @api_active_processing_time = xml_data['apiActiveProcessingTime'].to_i
        @api_version                = xml_data['apiVersion'].to_i
        @number_batches_completed   = xml_data['numberBatchesCompleted'].to_i
        @number_batches_failed      = xml_data['numberBatchesFailed'].to_i
        @number_batches_in_progress = xml_data['numberBatchesInProgress'].to_i
        @number_batches_queued      = xml_data['numberBatchesQueued'].to_i
        @number_batches_total       = xml_data['numberBatchesTotal'].to_i
        @number_records_failed      = xml_data['numberRecordsFailed'].to_i
        @number_records_processed   = xml_data['numberRecordsProcessed'].to_i
        @number_retries             = xml_data['numberRetries'].to_i
        @total_batches              = xml_data['totalBatches'].to_i
        @total_processing_time      = xml_data['totalProcessingTime'].to_i
      end
    end
  end
end
