require 'fastercsv'

module Kickit

  # provides convenience methods for accessing data
  # exported from kickapps.
  class Csv

    attr_reader :columns, :rows

    def initialize(columns = [], rows = [])
      @columns = columns
      @rows = []
      rows.each do |row|
        if row.kind_of? Row
          @rows << row
        else
          @rows << Row.new(self, row)
        end
      end
    end

    # returns a new Csv with the selected set of rows or nil if no rows
    # are selected
    def select(&block)
      selected_rows = @rows.select {|row| block.call(row)}
      unless (selected_rows.empty?)
        Csv.new(@columns, selected_rows)
      end
    end

    # parses and export file from the kickapps admin.
    # This expects the first line of the csv file to include the column
    # names.  
    def self.parse(file)
      columns = []
      rows = []
      csv = FasterCSV.read(file.path)
      csv.each do |row|
        if columns.empty?
          row.each do |col|
            val = col ? col.strip.underscore.parameterize.underscore : nil
            columns << val
          end
        else
          rows << row
        end
      end
      Csv.new(columns, rows)
    end

    # wrapper class around a row
    class Row
      def initialize(csv, row)
        @csv = csv
        @row = row
      end

      def includes?(column_name)
        @csv.columns.include?(column_name)
      end

      def method_missing(m, *args)
        if includes?(m.to_s)
          @row[@csv.columns.index(m.to_s)]
        elsif @row.respond_to? m
          if args.empty?
            @row.send(m)
          else
            @row.send(m, args)
          end
        end
      end

      def respond_to?(m, include_private = false)
        if includes?(m.to_s) || @row.respond_to?(m)
          true
        else
          super
        end
      end
    end

  end

end
