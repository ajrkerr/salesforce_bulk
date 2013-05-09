require 'rubygems'

#Test Frameworks
require 'test/unit'
require 'shoulda'

#Object/Web Mocking
require 'mocha/setup'
require 'webmock/test_unit'

#Testing Coverage
require 'simplecov'

SimpleCov.start do
  add_filter "/test/"
end

#Our Libraries
require 'salesforce_bulk2'
require 'xmlsimple'

# Helper Methods
class Test::Unit::TestCase
  
  def self.test name, &block
    define_method("test #{name.inspect}", &block)
  end
  

  def api_url client
    "https://#{client.login_host}/services/async/#{client.version}/"
  end
  
  ##
  # Bypass Client Authentication requirement for testing
  def bypass_authentication client
    client.instance_variable_set('@session_id', '123456789')
    client.instance_variable_set('@login_host', 'na9.salesforce.com')
    client.instance_variable_set('@instance_host', 'na9.salesforce.com')
  end
  
  def fixture_path file
    File.expand_path("../fixtures/#{file}", __FILE__)
  end
  
  ##
  # Read a file in as a string
  def fixture file
    File.new(fixture_path(file)).read
  end

  ##
  # Returns parsed XML
  def xml_fixture file
    XmlSimple.xml_in(fixture(file), :ForceArray => false)
  end
end