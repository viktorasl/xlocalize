require 'xlocalize/version'
require 'xlocalize/executor'
require 'xlocalize/webtranslateit'
require 'commander'

module Xlocalize
  class XlocalizeCLI
    include Commander::Methods

    def define_export_cmd
      command :export do |c|
        c.syntax = 'xlocalize export [options]'
        c.description = 'Export localized strings from Xcode project'
        c.option '--wti_key STRING', String, 'Webtranslateit API key'
        c.option '--project STRING', String, 'Path to project file'
        c.option '--target STRING', String, 'Target in the project'
        c.option '--excl_prefix STRING', String, 'Exclude strings having specified prefix'
        c.option '--master_lang STRING', String, 'Master language of the project'
        c.action do |_, options|
          if options.project.nil? or
             options.target.nil? or
             options.excl_prefix.nil? or
             options.master_lang.nil?
            raise 'Missing parameter'
          end

          wti = WebtranslateIt.new(options.wti_key) if !options.wti_key.nil?
          Executor.new.export_master(wti, options.project, options.target, options.excl_prefix, options.master_lang)
        end
      end
    end

    def define_download_cmd
      command :download do |c|
        c.syntax = 'xlocalize download [options]'
        c.description = 'Download localized strings from WebtranslateIt project'
        c.option '--wti_key STRING', String, 'Webtranslateit API key'
        c.option '--locales ARRAY', Array, 'Locales to download'
        c.action do |_, options|
          if options.wti_key.nil? or
             options.locales.nil?
            raise 'Missing parameter'
          end

          Executor.new.download(WebtranslateIt.new(options.wti_key), options.locales)
        end
      end
    end

    def define_import_cmd
      command :import do |c|
        c.syntax = 'xlocalize import [options]'
        c.description = 'Import localized strings to Xcode project'
        c.option '--locales ARRAY', Array, 'Locales to import'
        c.action do |_, options|
          if options.locales.nil?
            raise 'Missing parameter'
          end

          Executor.new.import(options.locales)
        end
      end
    end

    def run
      program :name, 'Xlocalize'
      program :version, Xlocalize::VERSION
      program :description, Xlocalize::DESCRIPTION

      define_export_cmd
      define_download_cmd
      define_import_cmd
      
      run!
    end
  end
end
