##
# This class provides an interface to interact with bulk batches in Salesforce.
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  class Batch
    attr_reader :id
    attr_reader :job_id
    attr_reader :data
    attr_reader :client

    ##
    # Createa a new batch
    def initialize job, batch_info
      @job = job
      @job_id = job.id
      @client = job.client
      @batch_info = batch_info
      @id = batch_info.id
    end

    ##
    # Finds an existing batch for a job
    def self.find job, batch_id
      job_id = job.id
      batch_info = Envelopes::BatchInfo.new(client.http_get_xml("job/#{job_id}/batch/#{batch_id}"))

      return Batch.new(job, batch_info)
    end

    ##
    # Refreshes the current batch
    def refresh
      @batch_info = Envelopes::BatchInfo.new(client.http_get_xml("job/#{job_id}/batch/#{batch_id}"))
    end

    ##
    # True if this is a query (which it is not)
    def query?
      false
    end

    ## 
    # Retrieve the content type of the transaction
    def content_type
      @job.content_type
    end

    ##
    # Returns the original request for this batch
    def request
      @request ||= BatchRequest.find(self)
    end
    
    ## 
    # Returns the results for this batch
    def result
      @result ||= BatchResult.find(self)
    end

    ### State Information ###
    # These helpers provide quick accessors to check the status of the batch
    # Refer to the official Salesforce documentation for the meaning and
    # progression of batch statuses

    ##
    # True if the batch is being processed
    def in_progress?
      state? 'InProgress'
    end
    
    ##
    # True if the batch is waiting to be processed
    def queued?
      state? 'Queued'
    end
    
    ##
    # True if the job has run to completion
    def completed?
      state? 'Completed'
    end
    
    ##
    # True if the batch has failed and was unable to finish
    def failed?
      state? 'Failed'
    end

    ##
    # True if the batch won't be processed (aka aborted job)
    def not_processed?
      state? 'Not Processed'
    end
    
    ##
    # True if the batch is not and will not run
    def finished?
      completed? or failed?
    end

    ## 
    # Helper to grab the state
    def state?(value)
      self.state.present? && self.state.casecmp(value) == 0
    end

    def state
      @batch_info.state
    end

    ##
    # Indicates that some records has errors
    def errors?
      failed? or number_records_failed > 0
    end

    ##
    # True if the batch is done and there are no errors
    def successful?
      completed? and !errors?
    end


    ### Delegate extra methods to BatchInfo ###

    ##
    # Delegate methods to batch_info
    def method_missing method, *args, &block
      @batch_info.send(method, *args, &block) or
      super
    end

    ##
    # Ensure that we report we can respond to these methods
    def respond_to? method, include_all = false
      @batch_info.respond_to?(method, include_all) or
      super
    end
  end
end