
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