require 'test_helper'

class TestInitialization < Test::Unit::TestCase
  
  ##
  # Configure the tests
  def setup
    @options = {
      :username => 'MyUsername',
      :password => 'MyPassword',
      :token => 'MySecurityToken'
    }
    
    @client = SalesforceBulk2::Client.new(@options)
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
    @options.merge!({
      :host => 'newhost.salesforce.com', 
      :version => 1.0,
      :port => 12345
    })
    
    client = SalesforceBulk2::Client.new(@options)
    
    assert_equal client.username, @options[:username]
    assert_equal client.password, "#{@options[:password]}#{@options[:token]}"
    assert_equal client.token, @options[:token]
    assert_equal client.login_host, @options[:host]
    assert_equal client.version, @options[:version]
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
    headers = {'Content-Type' => 'application/xml', 'SOAPAction' => 'login'}
    request = fixture("login_request.xml")
    response = fixture("login_response.xml")
    
    # Stub out the HTTP request
    stub_request(:post, "https://#{@client.login_host}/services/Soap/u/27.0")
      .with(:body => request, :headers => headers)
      .to_return(:body => response, :status => 200)
    
    @client.connect()
    
    assert_requested :post, "https://#{@client.login_host}/services/Soap/u/27.0", :body => request, :headers => headers, :times => 1
    
    assert_equal @client.instance_host, 'na9-api.salesforce.com'
    assert_equal @client.instance_variable_get('@session_id'), '00DE0000000YSKp!AQ4AQNQhDKLMORZx2NwZppuKfure.ChCmdI3S35PPxpNA5MHb3ZVxhYd5STM3euVJTI5.39s.jOBT.3mKdZ3BWFDdIrddS8O'
  end
  
  ##
  # Test teh parsing method
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