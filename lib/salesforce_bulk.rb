require 'net/https'
require 'xmlsimple'
require 'csv'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/keys'
require 'salesforce_bulk/version'
require 'salesforce_bulk/core_extensions/string'
require 'salesforce_bulk/salesforce_error'
require 'salesforce_bulk/connection'
require 'salesforce_bulk/client'
require 'salesforce_bulk/job'
require 'salesforce_bulk/batch'
require 'salesforce_bulk/batch_result'
require 'salesforce_bulk/batch_result_collection'
require 'salesforce_bulk/query_result_collection'

module SalesforceBulk
end