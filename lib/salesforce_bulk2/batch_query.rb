# batch_query.rb
# Author: Adam Kerr <adam.kerr@zucora.com>
# Date:   May 7th, 2013
# Description: A special type of batch for query operations

module SalesforceBulk2
  class BatchQuery < Batch
    def request
      @request ||= QueryRequest.find(self)
    end

    def result
      @result ||= QueryResult.find(self)
    end

    def query_string
    end

    def query?
      true
    end
  end
end