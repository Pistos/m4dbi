require 'rubygems'
require 'rake'
require 'rake/clean'

$:.unshift File.join( File.dirname(__FILE__), "lib" )

$m4dbi_project_root = File.expand_path( File.dirname(__FILE__) )

# ------------------

def run_specs_against( driver, database = 'm4dbi', database2 = 'm4dbi2' )
  exec "M4DBI_DRIVER=#{driver} M4DBI_DATABASE=#{database} M4DBI_DATABASE2=#{database2} bacon #{$m4dbi_project_root}/spec/*.rb"
end

namespace :db do
  namespace :sqlite3 do
    desc 'Drop and recreate SQLite3 test database, with schema'
    task :reset do
      db_file = "#{$m4dbi_project_root}/m4dbi.sqlite3"
      db_file2 = "#{$m4dbi_project_root}/m4dbi2.sqlite3"
      exec "rm -f #{db_file}; cat #{$m4dbi_project_root}/spec/test-schema-sqlite.sql | sqlite3 #{db_file}; rm -f #{db_file2}; cat #{$m4dbi_project_root}/spec/test-schema-sqlite.sql | sqlite3 #{db_file2}"
    end
  end

  namespace :postgresql do
    desc 'Drop and recreate PostgreSQL test database, with schema'
    task :reset do
      exec "dropdb -U postgres m4dbi; createdb -U postgres -O m4dbi m4dbi; cat #{$m4dbi_project_root}/spec/test-schema-postgresql.sql | psql -U m4dbi m4dbi"
    end
  end

  namespace :mysql do
    desc 'Create MySQL test database, with schema'
    task :init do
      exec "echo 'CREATE DATABASE m4dbi; CREATE DATABASE m4dbi2' | mysql -u root -p; cat #{$m4dbi_project_root}/spec/test-schema-mysql.sql | mysql -u m4dbi -p m4dbi; cat #{$m4dbi_project_root}/spec/test-schema-mysql.sql | mysql -u m4dbi -p m4dbi2"
    end

    desc 'Drop and recreate MySQL test database, with schema'
    task :reset do
      exec "echo 'DROP DATABASE m4dbi; CREATE DATABASE m4dbi; DROP DATABASE m4dbi2; CREATE DATABASE m4dbi2;' | mysql -u root -p; cat #{$m4dbi_project_root}/spec/test-schema-mysql.sql | mysql -u m4dbi -p m4dbi; cat #{$m4dbi_project_root}/spec/test-schema-mysql.sql | mysql -u m4dbi -p m4dbi2"
    end
  end
end

namespace :spec do
  desc 'Run specs against PostgreSQL driver'
  task :postgresql do
    run_specs_against 'PostgreSQL'
  end
  task :pg => 'postgresql'

  desc 'Run specs against MySQL driver'
  task :mysql do
    run_specs_against 'MySQL'
  end

  desc 'Run specs against SQLite3 driver'
  task :sqlite3 do
    run_specs_against 'SQLite3', 'm4dbi.sqlite3', 'm4dbi2.sqlite3'
  end

  task :all => [ :pg, :mysql ]
end

desc 'Run specs against all database drivers'
task :spec => 'spec:all'

task :default => :spec
task :test => :spec
