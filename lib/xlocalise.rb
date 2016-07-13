require 'xlocalise/version'
require 'xlocalise/executor'
require 'xlocalise/webtranslateit'
require 'commander'

module Xlocalise
  class XlocaliseCLI
    include Commander::Methods

    def global_opts_valid(global_opts)
      if global_opts[:project].nil? or
         global_opts[:target].nil? or
         global_opts[:excl_prefix].nil? or
         global_opts[:master_lang].nil?
        return false
      else
        return true
      end
    end

    def run
      program :name, 'Xlocalise'
      program :version, Xlocalise::VERSION
      program :description, Xlocalise::DESCRIPTION

      global_opts = {}
      wti = nil

      global_option('--wti_key KEY', '-w', 'Webtranslateit API key'){ |key| wti = WebtranslateIt.new(key) }
      global_option('--project PROJECT', '-p', 'Path to project file'){ |project| global_opts[:project] = project }
      global_option('--target TARGET', '-t', 'Target in the project'){ |target| global_opts[:target] = target }
      global_option('--excl_prefix EXCL_PREFIX', '-e', 'Exclude strings having specified prefix'){ |excl_prefix| global_opts[:excl_prefix] = excl_prefix }
      global_option('--master_lang MASTER_LANG', '-m', 'Master language of the project'){ |master_lang| global_opts[:master_lang] = master_lang }

      command :export do |c|
        c.syntax = 'xlocalise export [options]'
        c.description = 'Export localised strings from Xcode project'
        c.action do |args, options|
          if global_opts_valid(global_opts)
            xlc = Executor.new(wti, global_opts[:project], global_opts[:target], global_opts[:excl_prefix], global_opts[:master_lang])
            xlc.export_master
          else
            puts 'Missing definitions of global options'
          end
        end
      end

      command :import do |c|
        c.syntax = 'xlocalise import [options]'
        c.description = 'Import localised strings to Xcode project'
        c.option '--locales ARRAY', Array, 'Imports localised strings from Webtranslateit for given locales'
        c.action do |args, options|
          options.default :locales => []
          if global_opts_valid(global_opts)
            puts 'Import'
          else
            puts 'Missing definitions of global options'
          end
        end
      end

      run!
    end
  end
end

Xlocalise::XlocaliseCLI.new.run if __FILE__ == $0
