require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter('./spec/')
end
Bundler.setup

require 'xlocalize'

RSpec.configure do |config|
  # some (optional) config here
end
