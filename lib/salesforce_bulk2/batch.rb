# batch.rb
# Author: Adam Kerr <adam.kerr@zucora.com>
# Date:   May 7th, 2013
# Description: An object for interacting with batches in Salesforce

module SalesforceBulk2
  class Batch
    attr_reader :id
    attr_reader :job_id
    attr_reader :data

    def initialize job, batch_info
      @job = job
      @job_id = job.id
      @client = job.client
      @batch_info = batch_info
    end

    def self.find job, batch_id
      batch = Batch.new(job)
      batch.id = batch_id
      batch.refresh

      return batch
    end

    def client
      job.client
    end

    def request
      @request ||= BatchRequest.find(self)
    end
    
    def result
      @result ||= BatchResult.find(self)
    end

    ### State Information ###
    def executed? 
      @data.nil?
    end

    def in_progress?
      state? 'InProgress'
    end
    
    def queued?
      state? 'Queued'
    end
    
    def completed?
      state? 'Completed'
    end
    
    def failed?
      state? 'Failed'
    end
    
    def finished?
      completed? or failed?
    end

    def state?(value)
      self.state.present? && self.state.casecmp(value) == 0
    end

    def state
      @batch_info.state_message
    end

    def errors?
      number_records_failed > 0
    end

    def refresh
      @batch_info = BatchInfo.find(self)
    end

    # False because this is not a query operation
    def query?
      false
    end
  end
end