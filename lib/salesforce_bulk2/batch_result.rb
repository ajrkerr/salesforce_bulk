###
# This guy acts like a glorified hash
# Whatever is set is considered to be accessible as an attribute.
# 
# ie. 
#   result['marko'] = 'polo'
#   result.marko == 'polo'
##
module SalesforceBulk2
  class BatchResult
    attr_reader :id
    attr_reader :success
    attr_reader :created
    attr_reader :error

    attr_accessor :request

    def initialize(id, success, created, error = nil, request = nil)
      @id = id
      @success = (success == true)
      @created = (created == true)
      @error = error
      @request = request
    end
    
    def error?
      @error.nil?
    end
    
    def created?
      @created
    end
    
    def successful?
      @success
    end
    
    def updated?
      !created && success
    end
  end
end
