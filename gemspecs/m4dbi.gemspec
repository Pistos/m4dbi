#!/usr/bin/env ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
    s.name = 'm4dbi'
    s.version = '0.7.0'
    s.summary = 'Models (and More) for DBI'
    s.description = 'M4DBI provides models, associations and some convenient extensions to Ruby DBI.'
    s.homepage = 'http://purepistos.net/m4dbi'
    s.add_dependency( 'metaid' )
    s.requirements << 'dbi'
    s.requirements << 'bacon (optional)'

    s.authors = [ 'Pistos' ]
    s.email = 'pistos at purepistos dot net'

    #s.platform = Gem::Platform::RUBY

    s.files = [
        'HIM',
        'READHIM',
        'CHANGELOG',
        'LICENCE',
        *( Dir[ 'lib/**/*.rb', 'spec/**/*.rb' ] )
    ]
    s.extra_rdoc_files = [
      'HIM', 'READHIM', 'CHANGELOG', 'LICENCE',
    ]
    s.test_files = Dir.glob( 'spec/*.rb' )
end

if $PROGRAM_NAME == __FILE__
    Gem::Builder.new( spec ).build
end