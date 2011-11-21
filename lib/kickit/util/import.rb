module Kickit

  module Import

    class Mongo

      attr_accessor :db, :collection, :dry_run, :options

      def initialize(file_name)
        @file_name = file_name
        @db='kickit'
        @collection='data'
        @dry_run=false
        @options = []
      end

      def execute()
        unless system 'which mongoimport'
          raise 'mongoimport is not in the current path'
        end

        unless (File.file?(@file_name))
          raise "export file #{@file_name} does not exist or is not a file"
        end

        file = File.open(@file_name)
        cols = get_columns(file)
        file.close

        # now create a copy of the file without the header line as
        # it doesn't look like you can tell mongoimport to skip this
        `tail -n +2 #{@file_name} > kickit_import.csv`

        command = "mongoimport --db '#{@db}' --collection '#{@collection}' --fields #{cols.join(',')} #{@options.join(',')} --type csv --file 'kickit_import.csv'"

        puts "#{command}"
        unless @dry_run
          system(command)
        end

        command
      end

      private

      # convert the column names into something more reasonable
      def get_columns(file)
        first_line = file.first
        columns = first_line.split(',')
        na = 0
        columns.collect! do |col|
          if col and !col.blank?
            col.strip.underscore.parameterize.underscore
          else
            na += 1
            "na#{na}"
          end
        end
      end
    end
  end

end

