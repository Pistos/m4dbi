require File.expand_path( '../../lib/m4dbi/version', __FILE__ )

spec = Gem::Specification.new do |s|
    s.name = 'm4dbi'
    s.version = M4DBI::VERSION
    s.summary = 'Models (and More) for RDBI'
    s.description = 'M4DBI provides models, associations and some convenient extensions to RDBI.'
    s.homepage = 'https://github.com/Pistos/m4dbi'
    s.add_dependency( 'metaid' )
    s.add_dependency( 'rdbi' )
    s.requirements << 'bacon (optional)'

    s.authors = [ 'Pistos' ]
    s.email = 'm4dbi dot pistos at purepistos dot net'

    #s.platform = Gem::Platform::RUBY

    s.files = [
        'README',
        'CHANGELOG',
        'LICENCE',
        *( Dir[ 'lib/**/*.rb', 'spec/**/*.rb' ] )
    ]
    s.extra_rdoc_files = [
      'README', 'CHANGELOG', 'LICENCE',
    ]
    s.test_files = Dir.glob( 'spec/*.rb' )
end
