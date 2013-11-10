require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'data_mapper'

class Player
  include DataMapper::Resource
  
  property :steam_id, String, :key => true
  property :account_id, String 
  property :name, String
  property :created_at, DateTime, :default => DateTime.now
end

class MatchDetail
  include DataMapper::Resource
  
  property :match_id, String, :key => true
  property :data, String
  has n, :players
  property :created_at, DateTime, :default => DateTime.now
end

class Hero
  include DataMapper::Resource
  
  property :hero_id, String, :key => true
  property :name, String
  property :dota_name, String
  property :created_at, DateTime, :default => DateTime.now
end
  
DataMapper.finalize
DataMapper::Model.raise_on_save_failure = true

class DataModel
  def self.connect
    return if @setup; @setup ||= true
    home = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
    DataMapper.setup(:default, "sqlite3://#{File.join(home, "db/dota_data.db")}")
    DataMapper.auto_upgrade!
  end
end

