# salesforce_bulk

## Overview

Salesforce Bulk is a simple Ruby gem for connecting to and using the [Salesforce Bulk API](http://www.salesforce.com/us/developer/docs/api_asynch/index.htm).

## Installation

Install SalesforceBulk from RubyGems:

    gem install salesforce_bulk

Or include it in your project's `Gemfile` with Bundler:

    gem 'salesforce_bulk'

## Contribute

To contribute, fork this repo, create a topic branch, make changes, then send a pull request. Pull requests without accompanying tests will *not* be accepted. To run tests in your fork, just do:

    bundle install
    rake

## Configuration and Initialization

### Basic Configuration

    require 'salesforce_bulk'
    
    client = SalesforceBulk2::Client.new(username: 'MyUsername', password: 'MyPassword', token: 'MySecurityToken')
    client.authenticate

Optional keys include host (default: login.salesforce.com), version (default: 24.0) and debugging (default: false).

### Configuring from a YAML file

The optional keys mentioned in the Basic Configuration section can also be used here.

    ---
    username: MyUsername
    password: MyPassword
    token: MySecurityToken

Then in a Ruby script:

    require 'salesforce_bulk'
    
    client = SalesforceBulk2::Client.new("config/salesforce_bulk.yml")
    client.authenticate

## Usage Examples

Some requirements if you are moving from an older version of the gem. You must specify every key even if it has no value for each hash in the data array for a batch.

### Basic Example

    data1 = [{:Name__c => 'Test 1'}, {:Name__c => 'Test 2'}]
    data2 = [{:Name__c => 'Test 3'}, {:Name__c => 'Test 4'}]
    
    job = client.add_job(:insert, :MyObject__c)
    
    # easily add multiple batches to a job
    batch = client.add_batch(job.id, data1)
    batch = client.add_batch(job.id, data2)
    
    job = client.close_job(job.id) # or use the abort_job(id) method

### Adding a Job

When adding a job you can specify the following operations for the first argument:
- :delete
- :insert
- :update
- :upsert
- :query

When using the :upsert operation you must specify an external ID field name:

    job = client.add_job(:upsert, :MyObject__c, :external_id => :MyId__c)

For any operation you should be able to specify a concurrency mode. The default is Parallel. The other choice is Serial.

    job = client.add_job(:upsert, :MyObject__c, :concurrency_mode => :Serial, :external_id => :MyId__c)

### Retrieving Info for a Job

    job = client.job_info(jobId) # returns a Job object
    
    puts "Job #{job.id} is closed." if job.closed? # other: open?, aborted?

### Retrieving Info for all Batches

    batches = client.batch_info_list(jobId) # returns an Array of Batch objects
    
    batches.each do |batch|
      puts "Batch #{batch.id} failed." if batch.failed? # other: completed?, failed?, in_progress?, queued?
    end

### Retrieving Info for a single Batch

    batch = client.batch_info(jobId, batchId) # returns a Batch object
    
    puts "Batch #{batch.id} is in progress." if batch.in_progress?

### Retrieving Batch Results (for Delete, Insert, Update and Upsert)

To verify that a batch completed successfully or failed call the `batch_info` or `batch_info_list` methods first, otherwise if you call `batch_result` without verifying and the batch failed the method will raise an error.

The object returned from the following example only applies to the operations: delete, insert, update and upsert. Query results are handled differently.

    results = client.batch_result(jobId, batchId) # returns an Array of BatchResult objects
    
    results.each do |result|
      puts "Item #{result.id} had an error of: #{result.error}" if result.error?
    end

### Retrieving Query based Batch Results

To verify that a batch completed successfully or failed call the `batch_info` or `batch_info_list` methods first, otherwise if you call `batch_result` without verifying and the batch failed the method will raise an error.

Query results are handled differently as the response will not contain the full result set. You'll have to page through sets if you added multiple batches to a job.

    # returns a QueryResultCollection object (an Array)
    results = client.batch_result(jobId, batchId)
    
    while results.any?
      
      # Assuming query was: SELECT Id, Name, CustomField__c FROM Account
      results.each do |result|
        puts result[:Id], result[:Name], result[:CustomField__c]
      end
      
      puts "Another set is available." if results.next?
      
      results.next
      
    end

## Copyright

Copyright (c) 2011 Jorge Valdivia.

Copyright (c) 2012 Javier Julio.
