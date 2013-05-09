##
# Wraps each record in the batch result with a cleaner interface
# Author:: Adam Kerr <adam.kerr@zucora.com>
#

module SalesforceBulk2
  class BatchResultRecord
    attr_reader :id      # Salesforce ID
    attr_reader :success # True if success
    attr_reader :created # True if the record was created
    attr_reader :error   # Contains error message if present

    ##
    # Creates a new batch result record
    def initialize id, success, created, error = nil
      @id       = id
      @success  = parse_boolean(success)
      @created  = parse_boolean(created)
      @error    = error
    end
    
    ##
    # True if we suffered an error
    def error?
      @error.nil? or !successful?
    end
    
    ##
    # True if the record was created
    def created?
      @created
    end
    
    ##
    # True if this record finished withotu problem
    def successful?
      @success
    end
    
    ##
    # True if the record was updated and not created
    def updated?
      !created && successful?
    end

  private
    ##
    # True if Salesforce sent us back "true"
    def parse_boolean value
      value.is_a?(String) and value.strip.casecmp("true") == 0
    end
  end
end