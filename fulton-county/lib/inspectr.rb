require 'sinatra/base'
require 'pry'
require 'inspectr/version'
require 'inspectr/searcher'
require 'json'



module Inspectr
  class App < Sinatra::Base
    set :restaurants, Searcher.new
    enable :logging


    get '/' do
      if params['name']
        @matches = settings.restaurants.match_name(params['name'])
      end
      erb :index
    end

    get '/api' do
      content_type :json
      total = settings.restaurants.total.to_json
    end

    get '/api/restaurant/:name' do
      content_type :json
      @matches = settings.restaurants.match_name(params[:name.to_s]).to_json
    end

    get '/api/grade/:grade' do
      content_type :json
      @matches = settings.restaurants.match_grade(params[:grade.to_s]).to_json
    end

    get '/api/city/:city' do
      content_type :json
      @matches = settings.restaurants.match_city(params[:city.to_s]).to_json
    end

    get '/api/state/:state' do
      content_type :json
      @matches = settings.restaurants.match_state(params[:state.to_s]).to_json
    end

    get '/api/zipcode/:zipcode' do
      content_type :json
      @matches = settings.restaurants.match_zipcode(params[:zipcode.to_s]).to_json
    end

    # Here name == restaurant name
    get '/search_name' do
      if params['name']
        @matches = settings.restaurants.match_name(params['name'])
      end
      erb :index
    end

    get '/search_grade' do
      if params['name']
        @matches = settings.restaurants.match_grade(params['grade'])
      end
      erb :index
    end

    get '/search_city' do
      if params['city']
        @matches = settings.restaurants.match_city(params['city'])
      end
      erb :index
    end

    get '/search_state' do
      if params['state']
        @matches = settings.restaurants.match_state(params['state'])
      end
      erb :index
    end

    get '/search_zipcode' do
      if params['zipcode']
        @matches = settings.restaurants.match_zipcode(params['zipcode'])
      end
      erb :index
    end

    run! if app_file == $0
  end
end

