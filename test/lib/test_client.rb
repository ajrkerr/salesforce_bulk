require 'test_helper'

class TestClient < Test::Unit::TestCase
  
  ##
  # Default variables for the test
  def setup
    ## Required parameters for client
    @options = {
      :username => 'MyUsername',
      :password => 'MyPassword',
      :token => 'MySecurityToken'
    }
    
    @test_path = "/SomePath"
    @test_body = "SomeBody"
    @test_headers = { 'RandomHeader' => 'polo' }
    @test_response = "SomeResponse"
    @test_response_xml = fixture("test_response.xml")

    # Create objects
    @client = ::SalesforceBulk2::Client.new(@options)

    @authenticated_client = ::SalesforceBulk2::Client.new(@options)
    bypass_authentication(@authenticated_client)

    @test_url = build_url(@authenticated_client, @test_path)
    
    # @job_info = ::SalesforceBulk2::Envelopes::JobInfo.new(xml_fixture("job_info_response.xml"))
    # @batch_info = ::SalesforceBulk2::Envelopes::BatchInfo.new(xml_fixture("batch_info_response.xml"))
    
    # @job = ::SalesforceBulk2::Job.new(@client, @job_info)
    # @batch = ::SalesforceBulk2::Batch.new(@job, @batch_info)
  end
  

  ##
  # Verify exceptions are thrown on username and password
  test "validates username and password exist" do
    assert_raise ArgumentError do
      ::SalesforceBulk2::Client.new
    end

    assert_raise ArgumentError do
      ::SalesforceBulk2::Client.new(:username => 'username')
    end

    assert_raise ArgumentError do
      ::SalesforceBulk2::Client.new(:password => 'password')
    end
  end

  ##
  # Verifies default values for a client
  test "initialization with default values" do
    assert_not_nil @client
    assert_equal @client.username, @options[:username]
    assert_equal @client.password, "#{@options[:password]}#{@options[:token]}"
    assert_equal @client.token, @options[:token]
    assert_equal @client.login_host, 'login.salesforce.com'
    assert_equal @client.version, 27.0
    assert_equal @client.port, 443
  end
  
  ##
  # Verifies that all values can be safely overriden via API
  test "initialization overriding all default values" do
    options = @options.merge({
      :host => 'newhost.salesforce.com', 
      :version => 1.0,
      :port => 12345
    })
    
    client = SalesforceBulk2::Client.new(options)
    
    assert_equal client.username, options[:username]
    assert_equal client.password, "#{options[:password]}#{options[:token]}"
    assert_equal client.token, options[:token]
    assert_equal client.login_host, options[:host]
    assert_equal client.version, options[:version]
    assert_equal client.port, 12345
  end
  
  ##
  # Verify that it takes YAML config files
  test "initialization with a YAML file" do
    client = SalesforceBulk2::Client.new(fixture_path('config.yml'))
    
    assert_equal client.username, 'MyUsername'
    assert_equal client.password, 'MyPasswordMySecurityToken'
    assert_equal client.token, 'MySecurityToken'
    assert_equal client.login_host, 'myhost.mydomain.com'
    assert_equal client.version, 88.0
    assert_equal client.port, 12345
  end
  
  ##
  # Verifies that the client handles authentication passes successfully
  test "authentication" do
    headers  = {'Content-Type' => 'application/xml', 'SOAPAction' => 'login'}
    request  = fixture("login_request.xml")
    response = fixture("login_response.xml")
    
    # Stub out the HTTP request
    stub_request(:post, "https://#{@client.login_host}/services/Soap/u/27.0")
      .with(:body => request, :headers => headers)
      .to_return(:body => response, :status => 200)
    
    @client.connect()
    
    # Verify Request
    assert_requested :post, "https://#{@client.login_host}/services/Soap/u/27.0", 
      :body => request, 
      :headers => headers, 
      :times => 1
    
    assert_equal @client.instance_host, 'na9-api.salesforce.com'
    assert_equal @client.session_id, '00DE0000000YSKp!AQ4AQNQhDKLMORZx2NwZppuKfure.ChCmdI3S35PPxpNA5MHb3ZVxhYd5STM3euVJTI5.39s.jOBT.3mKdZ3BWFDdIrddS8O'
    assert @client.connected?
  end

  ##
  # Disconnect from salesforce
  test "disconnect" do
    headers  = {'Content-Type' => 'application/xml', 'SOAPAction' => 'logout'}
    request  = fixture("disconnect_request.xml")
    response = fixture("disconnect_response.xml")
    url = "https://#{@authenticated_client.instance_host}/services/Soap/u/27.0"
    
    # Stub out the HTTP request
    stub_request(:post, url)
      .with(:body => request, :headers => headers)
      .to_return(:body => response, :status => 200)
    
    @authenticated_client.disconnect

    # Verify Request
    assert_requested :post, url, 
      :body => request, 
      :headers => headers, 
      :times => 1

    assert  @authenticated_client.session_id.nil?
    assert !@authenticated_client.connected?
  end

  ##
  # Verify exceptions are thrown when we try to send an HTTP request before connecting
  test "does not allow a request when not authenticated" do
    assert !@client.connected?

    assert_raise SalesforceBulk2::Errors::NotLoggedInError do
      @client.http_get @test_path
    end

    assert_raise SalesforceBulk2::Errors::NotLoggedInError do
      @client.http_post @test_path, @test_body
    end

    assert_raise SalesforceBulk2::Errors::NotLoggedInError do
      @client.http_get_xml @test_path
    end

    assert_raise SalesforceBulk2::Errors::NotLoggedInError do
      @client.http_post_xml @test_path, @test_body
    end
  end

  ##
  # Verify we can extract content when authenticated
  test "allows requests to go through when authenticated" do
    ## Setup the HTTP stubs
    stub_request(:get, @test_url)
      .to_return(:body => @test_response, :status => 200)

    stub_request(:post, @test_url)
      .to_return(:body => @test_response, :status => 200)

    ## Send requests, verify intiail results
    result_get  = @authenticated_client.http_get( @test_path, @test_headers)
    result_post = @authenticated_client.http_post(@test_path, @test_body, @test_headers)

    assert result_get.body  == @test_response
    assert result_post.body == @test_response

    ## Verify our stubs were called correctly
    assert_requested :get,  @test_url, :times => 1, :headers => @test_headers
    assert_requested :post, @test_url, :times => 1, :headers => @test_headers, :body => @test_body
  end

  ##
  # Parses and returns XML properly
  test "parses XML responses properly XML" do
    ## Setup the HTTP stubs
    stub_request(:get, @test_url)
      .to_return(:body => @test_response_xml, :status => 200)

    stub_request(:post, @test_url)
      .to_return(:body => @test_response_xml, :status => 200)

    ## Send requests, verify intiail results
    response_get = @authenticated_client.http_get_xml(@test_path, @test_headers)
    response_post = @authenticated_client.http_post_xml(@test_path, @test_body, @test_headers)
    
    assert response_get['content'] == 'Marko'
    assert response_post['content'] == 'Marko'

    ## Verify our stubs were called correctly
    assert_requested :get, @test_url, :times => 1, :headers => @test_headers
    assert_requested :post, @test_url, :body => @test_body, :times => 1, :headers => @test_headers
  end

  ##
  # Properly reports a salesforce error
  test "Salesforce error" do
    response = fixture("invalid_error.xml")

    #Setup the error result
    stub_request(:get, @test_url)
      .to_return(:body => response, :status => 400)

    # Run the test
    assert_raise SalesforceBulk2::Errors::SalesforceError do
      @authenticated_client.http_get(@test_path, @test_headers)
    end
  end

  ##
  # Attempts to create a job
  test "Create job" do
  end

  ##
  # Closes all jobs that we have created
  test "Closes all jobs" do
  end

  ##
  # Aborts all jobs that we have created
  test "Aborts all jobs" do
  end

  ##
  # Clears our currently tracked jobs
  test "Clears all jobs" do
  end

  ##
  # Test the parsing method
  test "parsing instance id from server url" do
    # Happy path
    assert_equal @client.send(:get_instance_id, 'https://na1-api.salesforce.com'), 'na1-api'
    assert_equal @client.send(:get_instance_id, 'https://na23-api.salesforce.com'), 'na23-api'
    assert_equal @client.send(:get_instance_id, 'https://na345-api.salesforce.com'), 'na345-api'
    
    # protocol shouldn't matter, its just part of the host name we are after
    assert_equal @client.send(:get_instance_id, '://na1-api.salesforce.com'), 'na1-api'
    assert_equal @client.send(:get_instance_id, '://na23-api.salesforce.com'), 'na23-api'
    
    # in fact the .com portion shouldn't matter either
    assert_equal @client.send(:get_instance_id, '://na1-api.salesforce'), 'na1-api'
    assert_equal @client.send(:get_instance_id, '://na23-api.salesforce'), 'na23-api'
  end
  
end
