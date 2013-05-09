require 'test_helper'

class TestSimpleApi < Test::Unit::TestCase
  
  def setup
    options = {
      :username => 'myusername', 
      :password => 'mypassword',
      :token => "somelongtoken"
    }
    
    # Create objects
    @client = ::SalesforceBulk2::Client.new(options)
    @job_info = ::SalesforceBulk2::Envelopes::JobInfo.new(xml_fixture("job_info_response.xml"))
    @job = ::SalesforceBulk2::Job.new(@client, @job_info)
    @job.id = "123"
    @batch = ::SalesforceBulk2::Batch.new
    @batch.id = "456"
  end
  
  test "delete" do
    data = [{:Id => '123123'}, {:Id => '234234'}]
    
    @client.expects(:add_job).once.with(:delete, :VideoEvent__c, :external_id => nil).returns(@job)
    @client.expects(:add_batch).once.with(@job.id, data).returns(@batch)
    @client.expects(:close_job).once.with(@job.id).returns(@job)
    @client.expects(:batch_info).at_least_once.returns(@batch)
    @client.expects(:batch_result).once.with(@job.id, @batch.id)
    
    @client.delete(:VideoEvent__c, data)
  end
  
  test "insert" do
    data = [{:Title__c => 'Test Title'}, {:Title__c => 'Test Title'}]
    
    @client.expects(:add_job).once.with(:insert, :VideoEvent__c, :external_id => nil).returns(@job)
    @client.expects(:add_batch).once.with(@job.id, data).returns(@batch)
    @client.expects(:close_job).once.with(@job.id).returns(@job)
    @client.expects(:batch_info).at_least_once.returns(@batch)
    @client.expects(:batch_result).once.with(@job.id, @batch.id)
    
    @client.insert(:VideoEvent__c, data)
  end
  
  test "query" do
    data = 'SELECT Id, Name FROM Account'
    
    @client.expects(:add_job).once.with(:query, :VideoEvent__c, :external_id => nil).returns(@job)
    @client.expects(:add_batch).once.with(@job.id, data).returns(@batch)
    @client.expects(:close_job).once.with(@job.id).returns(@job)
    @client.expects(:batch_info).at_least_once.returns(@batch)
    @client.expects(:batch_result).once.with(@job.id, @batch.id)
    
    @client.query(:VideoEvent__c, data)
  end
  
  test "update" do
    data = [{:Id => '123123', :Title__c => 'Test Title'}, {:Id => '234234', :Title__c => 'A Second Title'}]
    
    @client.expects(:add_job).once.with(:update, :VideoEvent__c, :external_id => nil).returns(@job)
    @client.expects(:add_batch).once.with(@job.id, data).returns(@batch)
    @client.expects(:close_job).once.with(@job.id).returns(@job)
    @client.expects(:batch_info).at_least_once.returns(@batch)
    @client.expects(:batch_result).once.with(@job.id, @batch.id)
    
    @client.update(:VideoEvent__c, data)
  end
  
  test "upsert" do
    data = [{:Id__c => '123123', :Title__c => 'Test Title'}, {:Id__c => '234234', :Title__c => 'A Second Title'}]
    
    @client.expects(:add_job).once.with(:upsert, :VideoEvent__c, :external_id => :Id__c).returns(@job)
    @client.expects(:add_batch).once.with(@job.id, data).returns(@batch)
    @client.expects(:close_job).once.with(@job.id).returns(@job)
    @client.expects(:batch_info).at_least_once.returns(@batch)
    @client.expects(:batch_result).once.with(@job.id, @batch.id)
    
    @client.upsert(:VideoEvent__c, :Id__c, data)
  end
  
end