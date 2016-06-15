require 'open-uri'
require 'roo'
require 'pry'

# This returns an array of hashes with data for each row

module Inspectr
  class Searcher
    include Enumerable

    def initialize
      file = get_file
      @total = data_hash(file)
    end

    def total
      @total
    end

    def each
      @total.each { |x| yield(x) }
    end 

    def match_grade(grade)
      @matches = @total.select { |store| store['currentgrade'] =~ /#{grade}/i }
    end

    def match_name(name)
      @matches = @total.select { |store| store['restaurantname'] =~ /#{name}/i }
    end

    def match_city(city)
      @matches = @total.select { |store| store['City'] =~ /#{city}/i }
    end

    def match_state(state)
      @matches = @total.select { |store| store['State'] =~ /#{state}/i }
    end

    def match_zipcode(zipcode)
      @matches = @total.select { |store| store['zipcode'] == zipcode.to_i }
    end

    def list_restaurants
      @matches = @total.map { |restaurant| restaurant['restaurantname'] }.uniq
    end

    def list_cities
      @matches = @total.map { |restaurant| restaurant['City'] }.uniq
    end

protected
    def get_file
      file = Roo::Spreadsheet.open("./../restaurantrating.xlsx")
    end

    def columns(file)
      key = file.row(1)
    end

    def data_hash(file)
      total = []
      file.each do |rows|
        key = self.columns(file)
        values = rows
        values = values.map do |index|
          if index.instance_of? Float
            index = index.to_i
          elsif index.instance_of? Date
            index = index.to_s
          end
          index
        end 
        hash = Hash[key.zip values]
        total << hash
      end
      total.shift
      total
    end
  end
end
