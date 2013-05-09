##
# Error thrown when attempting to make a request when not logged in
# Author:: Adam Kerr <adam.kerr@zucora.com>

module SalesforceBulk2
  module Errors

    # An exception raised when any non successful request is made through the Salesforce Bulk API.
    class NotLoggedInError < StandardError 
    end
  end
end