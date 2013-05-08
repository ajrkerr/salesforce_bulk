# job_info.rb
# Author: Adam Kerr <adam.kerr@zucora.com>
# Date:   May 7th, 2013
# Description: A data structure to wrap the JobInfo requests in Salesforce

module SalesforceBulk
  module Communication
    class JobInfo
      @@fields = [:id, :operation, :object, :createdById, :state, :createdDate,
        :systemModstamp, :externalIdFieldName, :concurrencyMode, :contentType,
        :numberBatchesQueued, :numberBatchesInProgress, :numberBatchesCompleted,
        :numberBatchesFailed, :totalBatches, :retries, :numberRecordsProcessed,
        :numberRecordsFailed, :totalProcessingTime, :apiActiveProcessingTime,
        :apexProcessingTime, :apiVersion]
    end
  end
end
