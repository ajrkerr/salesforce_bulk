##
# Models the  object that Salesforce sends
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  class BatchRequest
    attr_reader :data
    attr_reader :original_data
    attr_reader :content_type

    ##
    # Creates a new batch Request object
    def initialize data, content_type
      @content_type = content_type
      @original_data = data
      @data = parse(data)
    end

    ##
    # Parses the request data from a string field
    def parse data
      case data
      when :csv
        return CSV.parse(body, :headers => true)
      when :xml
        return XmlSimple.xml_in(body)
      else
        return data
      end
    end

    ## 
    # Find the request a batch sent in
    def self.find batch
      client = batch.client
      job_id = batch.job_id
      batch_id = batch.id

      data = client.http_get("job/#{job_id}/batch/#{batch_id}/request")

      BatchRequest.new data, batch.content_type
    end
  end
end