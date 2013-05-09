##
# A quick helper module for collections
# It takes a list of boolean methods which it then maps as a filter
# Author:: Adam Kerr < adam.kerr@zucora.com>
=begin

== Example:

This allows us to do the following: 

  class Member
    def complete?
      true
    end

    def incomplete?
      false
    end
  end

  class Collection < Array
    @@filters = ['complete', 'incomplete']
    include Helpers::CollectionFilters
  end

  list = Collection.new(Member.new, Member.new, Member.new)
  list.complete   # => [Member, Member, Member]
  list.incomplete # => []

This is the equivilent of doing:

  class Collection < Array
    def complete
      select do |batch|
        batch.complete?
      end
    end

    def incomplete
      select do |batch|
        batch.incomplete?
      end
    end
  end

=end


module Helpers
  module CollectionFilters
    def self.included mod
      @@filters.each do |filter|
        mod.define_method filter.to_sym do
          select do |batch|
            batch.send("#{filter}?")
          end
        end
      end
    end
  end
end