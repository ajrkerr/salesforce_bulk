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
    ###
    # Returns the results of a query
    ##
    # def extract_query_data(batch_id, result_id)
    #   # Request results of this batch from Salesforce as a CSV
    #   headers = {"Content-Type" => "text/csv; charset=UTF-8"}
    #   response = @client.http_get("job/#{@job_id}/batch/#{batch_id}/result/#{result_id}", headers)
    #   result = []
      
    #   #Extract header row
    #   lines = response.body.lines.to_a
    #   headers = CSV.parse_line(lines.shift).collect { |header| header.to_sym }
      
    #   CSV.parse(lines.join, :headers => headers) do |row|
    #     result << Hash[row.headers.zip(row.fields)]
    #   end
      
    #   return result
    # end
    

      # response = @client.http_get("job/#{@job_id}/batch/#{@id}/result")

      # #Query Result
      # if response.body =~ /<.*?>/m
      #   result = XmlSimple.xml_in(response.body)
        
      #   if result['result'].present?
      #     data = extract_query_data(@id, result['result'].first)

      #     #TODO
      #     #Thar be dragons... I don't think that this be working at all.
      #     collection = QueryResultCollection.new(@client, @job_id, @id, result['result'].first, result['result'])
      #     collection.replace(data)
      #   end

      # #Batch Result
      # else
      #   results = BatchResultCollection.new
      #   request_data = get_request
        
      #   i = 0
      #   CSV.parse(response.body, :headers => true) do |row|
      #     result = BatchResult.new(row[0], row[1].to_b, row[2].to_b, row[3], request_data[i])
      #     results << result

      #     i += 1
      #   end
        
      #   return results
      # end