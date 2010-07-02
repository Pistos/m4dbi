require 'rubygems'
require 'rdbi'
require 'metaid'
require 'thread'

M4DBI_VERSION = '0.7.0'

__DIR__ = File.expand_path( File.dirname( __FILE__ ) )

require "#{__DIR__}/m4dbi/error"
require "#{__DIR__}/m4dbi/traits"
require "#{__DIR__}/m4dbi/hash"
require "#{__DIR__}/m4dbi/array"
require "#{__DIR__}/m4dbi/database-handle"
require "#{__DIR__}/m4dbi/row"
require "#{__DIR__}/m4dbi/timestamp"
require "#{__DIR__}/m4dbi/model"
require "#{__DIR__}/m4dbi/collection"

module M4DBI
  ancestral_trait_class_reader :last_dbh

  def self.connect( *args )
    dbh = M4DBI::Database.new( RDBI.connect( *args ) )
    trait :last_dbh => dbh
    dbh
  end
end