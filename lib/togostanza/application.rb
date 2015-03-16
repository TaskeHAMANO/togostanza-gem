require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'
require 'haml'

module TogoStanza
  class Application < Sinatra::Base
    set :root,       File.expand_path('../../..', __FILE__)
    set :haml,       escape_html: true
    set :protection, except: [:json_csrf, :frame_options]

    configure :development do
      register Sinatra::Reloader
    end

    helpers do
      def path(*paths)
        prefix = env['SCRIPT_NAME']

        [prefix, *paths].join('/').squeeze('/')
      end
    end

    get '/' do
      haml :index
    end

    get '/metadata.json' do
      metadata = {
        "@context" => {
          stanza: "http://togostanza.org/resource/stanza#"
        },
        "stanza:stanzas" => Stanza.all.map {|stanza| stanza.new.metadata }.compact
      }

      json metadata
    end

    get '/:id.json' do |id|
      json Stanza.find(id).new(params).context
    end

    get '/:id' do |id|
      Stanza.find(id).new(params).render
    end

    get '/:id/resources/:resource_id' do |id, resource_id|
      value = Stanza.find(id).new(params).resource(resource_id)

      json resource_id => value
    end

    get '/:id/help' do |id|
      stanza = Stanza.find(id).new

      haml :help, locals: {stanza: stanza.metadata}
    end

    get '/:id/text_search' do |id|
      @stanza    = Stanza.find(id).new
      stanza_uri = request.env['REQUEST_URI'].gsub(/\/text_search.*/, '')

      begin
        identifiers = @stanza.text_search(params[:q]).map {|param_hash|
          parameters = Rack::Utils.build_query(param_hash)
          "#{stanza_uri}?#{parameters}"
        }

        json enabled: true, count: identifiers.size, urls: identifiers
      rescue NoSearchDeclarationError
        json enabled: false, count: 0, urls: []
      end
    end

    get '/:id/metadata.json' do |id|
      @stanza = Stanza.find(id).new

      json @stanza.metadata
    end
  end
end
