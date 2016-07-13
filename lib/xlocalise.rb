require 'xlocalise/version'
require 'commander'

module Xlocalise
  class XlocaliseCLI
    include Commander::Methods

    def global_opts_valid(global_opts)
      if global_opts[:project].nil? or
         global_opts[:target].nil? or
         global_opts[:excl_prefix].nil?
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

      global_option('--project PROJECT', '-p', 'Path to project file'){ |project| global_opts[:project] = project }
      global_option('--target TARGET', '-t', 'Target in the project'){ |target| global_opts[:target] = target }
      global_option('--excl_prefix EXCL_PREFIX', '-e', 'Exclude strings having specified prefix'){ |excl_prefix| global_opts[:excl_prefix] = excl_prefix }

      command :export do |c|
        c.syntax = 'xlocalise export [options]'
        c.description = 'Export localised strings from Xcode project'
        c.option '--locales ARRAY', Array, 'Exports localised strings from Xcode project for given locales'
        c.action do |args, options|
          if global_opts_valid(global_opts)
            puts 'Export'
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
