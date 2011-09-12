require 'rubygems'
require 'rdbi'
require 'metaid'
require 'thread'

__DIR__ = File.expand_path( File.dirname( __FILE__ ) )

require "#{__DIR__}/m4dbi/version"
require "#{__DIR__}/m4dbi/error"
require "#{__DIR__}/m4dbi/traits"
require "#{__DIR__}/m4dbi/hash"
require "#{__DIR__}/m4dbi/array"
require "#{__DIR__}/m4dbi/database"
require "#{__DIR__}/m4dbi/statement"
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
