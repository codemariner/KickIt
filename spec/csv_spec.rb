require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'tempfile'
require 'kickit/util/csv'

describe Kickit::Csv do

  describe 'given a valid csv file' do

    before(:all) do
      @file = Tempfile.new('data')
      @file.print "name,first Name, last name,adminTags,\n"
      (1..10).each do |n|
        @file << "name #{n},fn#{n}, ln#{n}"
        # just trying to add user tag to every 3rd user
        if (n % 3) == 0
          @file.print ",user,\n"
        else
          @file.print ",,\n"
        end
      end
      @file.flush

      @file.close
      @file.open
      @csv = Kickit::Csv.parse @file
    end

    it 'should turn the column names into suitable method names' do
      @csv.columns.include?('name').should be_true
      @csv.columns.include?('first_name').should be_true
      @csv.columns.include?('last_name').should be_true
      @csv.columns.include?('admin_tags').should be_true
    end

    it 'should have all rows' do
      @csv.rows.size.should eql(10)
    end

    it 'should allow for selections' do
      csv = @csv.select {|row|
        row.admin_tags =~ /user/
      }
      csv.rows.size.should eql(3)
    end

    describe 'for each row' do

      it 'should provide for access to the row values based on the column name' do
        row = @csv.rows[0]
        row.respond_to?('admin_tags').should be_true
        row.admin_tags.should be_nil

        row = @csv.rows[2]
        row.admin_tags.should eql('user')
      end
    end

  end

end
