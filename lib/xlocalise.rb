require 'xlocalise/version'
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
        c.option '--locales ARRAY', Array, 'Exports localised strings from Xcode project for given locales'
        c.action do |args, options|
          puts 'Export'
        end
      end

      command :import do |c|
        c.syntax = 'xlocalise import [options]'
        c.description = 'Import localised strings to Xcode project'
        c.option '--locales ARRAY', Array, 'Imports localised strings from Webtranslateit for given locales'
        c.action do |args, options|
          options.default :locales => []
          puts 'Import'
        end
      end

      run!
    end
  end
end
