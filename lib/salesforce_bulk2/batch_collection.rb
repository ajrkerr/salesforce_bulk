##
# Provides some helper methods on a collection of batches.  
# Allows us to quickly filter/manipulate the entire selection.
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  class BatchCollection < Array

    ##
    # List of all filter methods
    @@filters = %w{in_progress queued completed failed not_processed fininshed successful}

    ##
    # Create a list of filter methods on the collection. 
    # Same as creating methods like:
    # def in_progress
    #   select do |batch|
    #     batch.in_progress?
    #   end
    # end
    #
    # +Examples+
    # collection.queued => returns all queued batches
    # collection.completed => returns all completed batches
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
    # Return an array of results for all batches
    def get_results
      map do |batch|
        batch.result
      end
    end

    ##
    # Return an array of all requests for known batches
    def get_requests
      map do |batch|
        batch.request
      end
    end

    ##
    # Refresh the batches from the server
    def refresh
      each do |batch|
        batch.refresh
      end
    end
  end
end