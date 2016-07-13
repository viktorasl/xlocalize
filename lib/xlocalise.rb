require 'xlocalise/version'
require 'xlocalise/executor'
require 'xlocalise/webtranslateit'
require 'commander'

module Xlocalise
  class XlocaliseCLI
    include Commander::Methods

    def run
      program :name, 'Xlocalise'
      program :version, Xlocalise::VERSION
      program :description, Xlocalise::DESCRIPTION

      command :export do |c|
        c.syntax = 'xlocalise export [options]'
        c.description = 'Export localised strings from Xcode project'
        c.option '--wti_key STRING', String, 'Webtranslateit API key'
        c.option '--project STRING', String, 'Path to project file'
        c.option '--target STRING', String, 'Target in the project'
        c.option '--excl_prefix STRING', String, 'Exclude strings having specified prefix'
        c.option '--master_lang STRING', String, 'Master language of the project'
        c.action do |args, options|
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

      command :download do |c|
        c.syntax = 'xlocalise download [options]'
        c.description = 'Download localized strings from WebtranslateIt project'
        c.option '--wti_key STRING', String, 'Webtranslateit API key'
        c.option '--locales ARRAY', Array, 'Locales to download'
        c.action do |args, options|
          if options.wti_key.nil? or
             options.locales.nil?
            raise 'Missing parameter'
          end

          Executor.new.download(WebtranslateIt.new(options.wti_key), options.locales)
        end
      end

      command :import do |c|
        c.syntax = 'xlocalise import [options]'
        c.description = 'Import localised strings to Xcode project'
        c.option '--locales ARRAY', Array, 'Locales to import'
        c.action do |args, options|
          if options.locales.nil?
            raise 'Missing parameter'
          end

          Executor.new.import(options.locales)
        end
      end

      run!
    end
  end
end
