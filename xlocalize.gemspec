# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xlocalize/version'

Gem::Specification.new do |spec|
  spec.name          = "xlocalize"
  spec.version       = Xlocalize::VERSION
  spec.authors       = ["Viktoras Laukevičius"]
  spec.email         = ["viktoras.laukevicius@yahoo.com"]

  spec.homepage      = "https://github.com/viktorasl/xlocalize"
  spec.summary       = Xlocalize::DESCRIPTION
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.0.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'nokogiri', '~> 1.8.2'
  spec.add_runtime_dependency 'commander', '~> 4.4'
  spec.add_runtime_dependency 'colorize', '~> 0.8'
  spec.add_runtime_dependency 'multipart-post', '~> 2.0'
  spec.add_runtime_dependency 'plist', '~> 3.2'
  spec.add_runtime_dependency 'apfel'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'simplecov', '~> 0.13'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
end
