require 'version'
require 'rest-client'
require 'json'
require 'model/dota_model'
require 'dm-sqlite-adapter'
require 'data_mapper'

module Dota2
  
  class RestAPI
    
    # Here is the magic offset used for convert Steam Id to account ID
    # What the fuck valve. What the actual fuck. 
    MAGIC_OFFSET = 76561197960265728 

    BASE_URL ='https://api.steampowered.com'
    MATCH_URL = { :url => 'IDOTA2Match_570', :version => 'v001'}
    ECON_URL = { :url => 'IEconDOTA2_570', :version => 'v0001'}
    USER_URL = { :url => 'ISteamUser', :version => 'v0002' }
    USER_RESOLVE_URL = { :url => 'ISteamUser', :version => 'v0001' }
    ECON_SCHEMA_URL = { :url => 'IEconItems_570', :version => 'v0001' }
   
  
    URLS = {
      :history => "#{BASE_URL}/IDOTA2Match_570/GetMatchHistory/v001",
      :history_seq => "#{BASE_URL}/IDOTA2Match_570/GetMatchDetailsBySequenceNum/v001",
      :details => "#{BASE_URL}/IDOTA2Match_570/GetMatchDetails/v001",
      :heroes => "#{BASE_URL}/IEconDOTA2_570/GetHeroes/v0001",
      :users => "#{BASE_URL}/ISteamUser/GetPlayerSumamries/v0002",
      :user_resolve => "#{BASE_URL}/ISteamUser/ResolveVanityURL/v0001",
      :econ_shema => "#{BASE_URL}/IEconItems_570/GetSchema/v0001"
    }
    
    attr_accessor :key, :locale, :cache
    
    def initialize key, locale = 'en_us'
      @key = key
      @locale = locale
      DataModel.connect
      DataMapper::Logger.new($stdout, :debug)
    end

  
    def get url, params = {:params => {}}
      params[:params][:key] = @key
      params[:params][:language] = @locale
      begin 
        JSON.parse RestClient.get(URLS[url], params), :symbolize_names => true
      rescue => e
        p e
        raise "Error: #{e.response}"
      end
    end
    
  
    def get_heroes
      cached_heroes = Hero.all
      return cached_heroes unless cached_heroes.empty?
      heroes = {}
      get(:heroes)[:result][:heroes].each do |h|
        heroes[h[:id]] = { :name => h[:localized_name] , :dota_name => h[:name] }
        Hero.create(
          :hero_id => h[:id],
          :name => h[:localized_name],
          :dota_name => h[:name]
        )
      end
      return Hero.all
    end
  
    def get_matches_for_name player_name, matches_requested = nil
      steam_id = get_steam_id player_name
      params = { :params => { :account_id => steam_id } }
      params[:params][:matches_requested] = num_matches if matches_requested 
      get_matches params
    end
  
    def get_a_z_matches player_name
      steam_id = get_steam_id(player_name).to_i
      account_id = steam_id - MAGIC_OFFSET
      heroes = get_heroes
      heroes_a_z = heroes.map { |id, data| data[:name] }.sort! 
      response = get_matches_for_name player_name
      matches = response[:result][:matches]

      curr_hero = nil
      matches.each do | match |
        player_data = match[:players].select { |p| p[:account_id] == account_id }
        raise "Player id not found! (Account id: #{account_id}, Steam id: #{steam_id}" if player_data.empty?
        hero_id = player_data.first[:hero_id] 
        puts "match: #{match[:match_id]} hero: #{hero_id}"
      end
    end 
      

    def get_steam_id name
      get(:user_resolve, :params => { :vanityurl => name})[:response][:steamid]
    end
    
    def get_matches params
      get(:history, params)
    end
    
    def get_match_details match_id
      get(:details, :params => { :match_id => match_id })
    end  

  end
 
end
