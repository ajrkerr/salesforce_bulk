##
# Provides some helper methods on a collection of jobs.  
# Allows us to quickly filter/manipulate the entire collection.
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  class JobCollection < Array

    ##
    # List of all filter methods
    @@filters = %w{batches_finished finished failed aborted closed open can_create_batches successful}

    ##
    # Create a list of filter methods on the collection. 
    # Same as creating methods like:
    # def failed
    #   select do |job|
    #     job.failed?
    #   end
    # end
    #
    # +Examples+
    # collection.failed => returns all failed jobs
    # collection.closed => returns all closed jobs
    #
    class << self
      @@filters.each do |filter|
        define_method filter.to_sym do
          select do |batch|
            batch.send("#{filter}?")
          end
        end
      end
    end

    ## 
    # Return an array of results for all jobs
    def get_results
      map do |job|
        job.get_results.flatten
      end
    end

    ##
    # Return an array of all requests for known jobs
    def get_requests
      map do |job|
        job.get_requests.flatten
      end
    end

    ##
    # Refresh the jobs from the server
    def refresh
      each do |job|
        job.refresh
      end
    end

    ##
    # Closes all jobs in the collection
    def close
      each do |job|
        job.close
      end
    end

    ##
    # Aborts all jobs in the collection
    def abort
      each do |job|
        job.abort
      end
    end
  end
end