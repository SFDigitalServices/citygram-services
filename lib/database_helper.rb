require 'dotenv'
Dotenv.load

require 'dedent'
require 'sequel'
require 'shellwords'
require 'uri'

Sequel.extension :migration

module Citygram
  module DatabaseHelper
    MIGRATION_TEMPLATE = <<-TEMPLATE.dedent.freeze
      Sequel.migration do
        up do
        end

        down do
        end
      end
    TEMPLATE

    def self.environment
      ENV['RACK_ENV'] ||= 'development'
    end

    def self.database_url
      ENV['DATABASE_URL'] ||= "postgres://localhost/citygram_#{environment}"
    end

    def self.master_database
      @master_database ||= Sequel.connect(URI(database_url).tap { |u| u.path = '/postgres' }.to_s)
    end

    def self.database
      @database ||= Sequel.connect(database_url)
    end

    def self.app_root
      @app_root ||= Shellwords.shellescape(File.expand_path('../../', __FILE__))
    end

    def self.migration_path
      @migration_path ||= File.join(app_root, 'db/migrations')
    end

    def self.schema_path
      @schema_path ||= File.join(app_root, 'db/schema.sql')
    end

    def self.db_name
      @db_name ||= URI(database_url).path.gsub('/', '')
    end

    def self.db_version
      database.tables.include?(:schema_info) ? database[:schema_info].first[:version].to_i : 0
    end

    def self.migrate_db(version = nil)
      if version
        Sequel::Migrator.run(database, migration_path, target: version.to_i)
      else
        Sequel::Migrator.run(database, migration_path)
      end

      schema_dump
    rescue Sequel::Migrator::Error => e
      puts e
    end

    def self.generate_migration(name)
      next_version = format('%03d', db_version + 1)
      path = "db/migrations/#{next_version}_#{name}.rb"
      File.write(path, MIGRATION_TEMPLATE+"\n")
    end

    def self.create_db
      master_database.run("CREATE DATABASE \"#{db_name}\"")
    end

    def self.drop_db
      database.disconnect
      master_database.run("DROP DATABASE \"#{db_name}\"")
    end

    def self.schema_dump
      database.extension :schema_dumper
      File.open('db/schema.rb', 'w') do |file|
        file.write(database.dump_schema_migration(same_db: true))
      end
    end

    def self.rollback_db(version = nil)
      previous_version = version || db_version - 1
      migrate_db(previous_version)
    end

    def self.reset
      drop_db
      create_db
      migrate_db
    end

    def self.console(ctx = self)
      require File.expand_path('../../app', __FILE__)
      if ENV['RACK_ENV'] == 'test'
        require 'factory_girl'
        require File.join(app_root, 'spec/factories')
        ctx.send :include, FactoryGirl::Syntax::Methods
      end
      require 'irb'
      ARGV.clear
      IRB.start
    end
  end
end
