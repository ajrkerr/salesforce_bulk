require 'bundler'
Bundler::GemHelper.install_tasks


##
# Default test task
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test


##
# Generate Documentation
namespace :doc do
  require 'rdoc/task'
  require File.expand_path('../lib/salesforce_bulk2/version', __FILE__)
  RDoc::Task.new do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "SalesforceBulk #{SalesforceBulk2::VERSION}"
    rdoc.main = 'README.md'
    rdoc.rdoc_files.include('README.md', 'LICENSE.md', 'lib/**/*.rb')
  end
end