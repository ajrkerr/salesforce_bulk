##
# Provides an interface for Salesforce's BatchResult.  
# Contains BatchResultRecords.
# Author:: Adam Kerr <adam.kerr@zucora.com>
#

module SalesforceBulk2
  class BatchResult < Array

    attr_reader :batch
    attr_reader :batch_id
    attr_reader :job
    attr_reader :job_id
    attr_reader :client
    attr_reader :content_type

    ##
    # List of all filter methods
    @@filters = %w{error created successful updated}

    ##
    # Create a list of filter methods on the collection. 
    # Same as creating methods like:
    # def updated
    #   select do |result|
    #     result.updated?
    #   end
    # end
    #
    # +Examples+
    # collection.queued => returns all queued results
    # collection.completed => returns all completed results
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
    # Creates a new results object
    def initialize batch
      @batch = batch
      @batch_id = batch.id
      
      @job = batch.job
      @job_id = batch.job_id

      @client = batch.client
      @content_type = batch.content_type
    end

    ##
    # Refresh the results from the server
    def refresh
      # Grab the updated information
      result = @client.http_get("job/#{@job_id}/batch/#{@batch_id}/result")
      
      # Parse results according to content type
      case content_type
      when :csv
        #Parse as a CSV file
        CSV.parse(result.body, :headers => true) do |record|
          self << BatchResultRecord.new(record[0], record[1], record[2], record[3])
        end

      when :xml
        #TODO Should probably test or verify this or something
        
        #Parse as XML
        XmlSimple.xml_in(result.body).each do |record|
          self << BatchResultRecord.new(record[:id], record[:success], record[:created], record[:error])
        end

      else
        raise ArgumentError "Invalid content type"
      end

      return true
    end

    ##
    # Finds the result associated with the batch
    def self.find batch
      result = BatchResult.new batch
      result.refresh
      return result
    end

    ##
    # True if any records failed
    def any_failures?
      self.any? { |result| result.error? }
    end
  end
end
