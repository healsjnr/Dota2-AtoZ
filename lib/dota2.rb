$:.unshift File.dirname(__FILE__)
require 'model/dota_model'
require 'controller/dota_api'
require 'pry'

module Dota2

  class Dota2AtoZ

    attr_reader :key    

    def initialize key
      @key = key
    end
    
    def generate_stats player_name
    end
  
  end
  
  binding.pry

end

