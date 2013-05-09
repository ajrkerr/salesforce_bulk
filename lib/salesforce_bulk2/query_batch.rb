##
#  A special type of batch for query operations
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  class QueryBatch < Batch

    ##
    # Returns a QueryRequest object
    def request
      @request ||= QueryRequest.find(self)
    end

    ##
    # Returns a QueryResult
    def result
      @result ||= QueryResult.find(self)
    end

    ##
    # Returns the SOQL string
    def query_string
      request.to_s
    end

    ##
    # Returns true if this is a batch query
    def query?
      true
    end
  end
end