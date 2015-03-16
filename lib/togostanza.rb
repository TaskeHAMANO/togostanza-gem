require 'togostanza/version'
require 'sprockets'

module TogoStanza
  autoload :Application, 'togostanza/application'
  autoload :CLI,         'togostanza/cli'
  autoload :Stanza,      'togostanza/stanza'

  class << self
    attr_accessor :text_search_method

    def configure
      yield self
    end

    def sprockets
      @sprockets ||= Sprockets::Environment.new.tap {|sprockets|
        sprockets.append_path File.expand_path('../../assets', __FILE__)
      }
    end
  end

  configure do |config|
    config.text_search_method = :regex
  end
end
