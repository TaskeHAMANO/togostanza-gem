require 'thor'
require 'active_support/all'

module TogoStanza
  module CLI
    class ProviderGenerator < Thor::Group
      include Thor::Actions

      argument :name

      def self.source_root
        File.expand_path('../../../templates/provider', __FILE__)
      end

      def create_files
        template 'gitignore.erb',         "#{name}/.gitignore"
        template 'Gemfile.erb',           "#{name}/Gemfile"
        template 'config.ru.erb',         "#{name}/config.ru"
        template 'Procfile.erb',          "#{name}/Procfile"
        template 'config/unicorn.rb.erb', "#{name}/config/unicorn.rb"

        create_file "#{name}/log/.keep"
      end

      def init_repo
        inside name do
          run "bundle"
          run "git init ."
          run "git add -A"
        end
      end
    end

    class StanzaGenerator < Thor::Group
      include Thor::Actions

      argument :name

      def self.source_root
        File.expand_path('../../../templates/stanza', __FILE__)
      end

      def create_files
        template 'Gemfile.erb',       "#{file_name}/Gemfile"
        template 'gemspec.erb',       "#{file_name}/#{file_name}.gemspec"
        template 'lib.rb.erb',        "#{file_name}/lib/#{file_name}.rb"
        template 'stanza.rb.erb',     "#{file_name}/stanza.rb"
        template 'template.hbs.erb',  "#{file_name}/template.hbs"
        template 'metadata.json.erb', "#{file_name}/metadata.json"

        create_file "#{file_name}/assets/#{stanza_id}/.keep"
      end

      def inject_gem
        append_to_file 'Gemfile', "gem '#{file_name}', path: './#{file_name}'\n"
      end

      private

      def stanza_id
        name.underscore.sub(/_stanza$/, '')
      end

      def file_name
        stanza_id + '_stanza'
      end

      def class_name
        file_name.classify
      end

      def title
        stanza_id.titleize
      end
    end

    class NameModifier < Thor::Group
      include Thor::Actions

      argument :name1, type: :string
      argument :name2, type: :string

      def self.source_root
        File.expand_path('../../../templates/stanza', __FILE__)
      end

      def replace_description
        name1_chopped = chop_slash(name1)
        name2_chopped = chop_slash(name2)

        gsub_file("#{files_name(name1_chopped)}/help.md", titles(name1_chopped), titles(name2_chopped))
        gsub_file("#{files_name(name1_chopped)}/help.md", stanzas_id(name1_chopped), stanzas_id(name2_chopped))
        gsub_file("#{files_name(name1_chopped)}/#{files_name(name1_chopped)}.gemspec", files_name(name1_chopped), files_name(name2_chopped))
        gsub_file("#{files_name(name1_chopped)}/lib/#{files_name(name1_chopped)}.rb", classes_name(name1_chopped), classes_name(name2_chopped))

        unless File.exist?("#{files_name(name1_chopped)}/metadata.json")
          template 'metadata.json.erb', "#{file_name}/metadata.json"
        end

        gsub_file("#{files_name(name1_chopped)}/metadata.json", stanzas_id(name1_chopped), stanzas_id(name2_chopped))
        gsub_file("#{files_name(name1_chopped)}/stanza.rb", classes_name(name1_chopped), classes_name(name2_chopped))
        gsub_file("#{files_name(name1_chopped)}/template.hbs", titles(name1_chopped), titles(name2_chopped))
        gsub_file("#{files_name(name1_chopped)}/template.hbs", "assets/#{stanzas_id(name1_chopped)}","assets/#{stanzas_id(name2_chopped)}")
        gsub_file("#{files_name(name1_chopped)}/template.hbs", "#{stanzas_id(name1_chopped)}/resources", "#{stanzas_id(name2_chopped)}/resources")
        gsub_file('Gemfile', /\'#{files_name(name1_chopped)}\'/, "\'#{files_name(name2_chopped)}\'")
        gsub_file('Gemfile', /\'\.\/#{files_name(name1_chopped)}\'/, "\'\.\/#{files_name(name2_chopped)}\'")
      end

      def rename_directory
        name1_chopped = chop_slash(name1)
        name2_chopped = chop_slash(name2)

        unless File.exist?("#{files_name(name1_chopped)}/assets/#{stanzas_id(name1_chopped)}")
          Dir.mkdir("#{files_name(name1_chopped)}/assets/#{stanzas_id(name1_chopped)}")
        end

        File.rename("#{files_name(name1_chopped)}/assets/#{stanzas_id(name1_chopped)}", "#{files_name(name1_chopped)}/assets/#{stanzas_id(name2_chopped)}")
        File.rename("#{files_name(name1_chopped)}/lib/#{files_name(name1_chopped)}.rb", "#{files_name(name1_chopped)}/lib/#{files_name(name2_chopped)}.rb")
        File.rename("#{files_name(name1_chopped)}/#{files_name(name1_chopped)}.gemspec", "#{files_name(name1_chopped)}/#{files_name(name2_chopped)}.gemspec")
        File.rename(files_name(name1_chopped), files_name(name2_chopped))
      end

      private

      def chop_slash(name)
        if name[-1] == '/'
          name.chop
        else
          name
        end
      end

      def stanza_id
        name1_chopped = chop_slash(name1)
        name1_chopped.underscore.sub(/_stanza$/, '')
      end

      def file_name
        stanza_id + '_stanza'
      end

      def stanzas_id(name)
        name.underscore.sub(/_stanza$/, '')
      end

      def files_name(name)
        stanzas_id(name) + '_stanza'
      end

      def classes_name(name)
        files_name(name).classify
      end

      def titles(name)
        stanzas_id(name).titleize
      end
    end

    class NameRegister < Thor::Group
      include Thor::Actions

      argument :name

      def template_dir
        File.expand_path('../../../templates/stanza', __FILE__)
      end

      def replace_author
        gsub_file("#{template_dir}/gemspec.erb", /spec.authors\s*=\s\[\'.*\'\]/, "spec.authors       = ['#{name}']")
        gsub_file("#{template_dir}/metadata.json.erb", /author":\s".*"/, "author\": \"#{name}\"")
      end
    end

    class MailRegister < Thor::Group
      include Thor::Actions

      argument :addr

      def template_dir
        File.expand_path('../../../templates/stanza', __FILE__)
      end

      def replace_author
        gsub_file("#{template_dir}/gemspec.erb", /spec.email\s*=\s\[\'.*\'\]/, "spec.email         = ['#{addr}']")
        gsub_file("#{template_dir}/metadata.json.erb", /address":\s".*"/, "address\": \"#{addr}\"")
      end
    end

    class Stanza < Thor
      register StanzaGenerator, 'new', 'new NAME', 'Creates a new stanza'
    end

    class Stanza < Thor
      register NameModifier, 'modify', 'modify OLD_NAME NEW_NAME', 'Modify a name of stanza'
    end

    class Root < Thor
      register NameRegister, 'name' , 'name NAME' , 'register your name'
    end

    class Root < Thor
      register MailRegister, 'mail' , 'mail ADDRESS' , 'register your mail'
    end

    class Root < Thor
      register ProviderGenerator, 'init', 'init NAME', 'Creates a new provider'

      desc 'stanza [COMMAND]', ''
      subcommand 'stanza', Stanza
    end
  end
end
