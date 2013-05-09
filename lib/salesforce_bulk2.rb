require 'net/https'
require 'xmlsimple'
require 'csv'

# require 'active_support'
# require 'active_support/inflector'
# require 'active_support/core_ext/object/blank'
# require 'active_support/core_ext/hash/keys'

require 'salesforce_bulk2/envelopes/batch_info'
require 'salesforce_bulk2/envelopes/job_info'

require 'salesforce_bulk2/client'
require 'salesforce_bulk2/batch'
require 'salesforce_bulk2/batch_collection'
require 'salesforce_bulk2/batch_result'
require 'salesforce_bulk2/batch_result_record'
require 'salesforce_bulk2/batch_result_collection'
require 'salesforce_bulk2/batch_request'

require 'salesforce_bulk2/job'
require 'salesforce_bulk2/job_collection'

require 'salesforce_bulk2/query_result'
require 'salesforce_bulk2/query_request'

require 'salesforce_bulk2/version'

require 'salesforce_bulk2/errors/salesforce_error'
require 'salesforce_bulk2/errors/not_logged_in_error'


module SalesforceBulk2
end