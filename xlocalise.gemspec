# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xlocalise/version'

Gem::Specification.new do |spec|
  spec.name          = "xlocalise"
  spec.version       = Xlocalise::VERSION
  spec.authors       = ["viktoras"]
  spec.email         = ["viktoras.laukevicius@yahoo.com"]

  spec.homepage      = "https://github.com/viktorasl"
  spec.summary       = Xlocalise::DESCRIPTION
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.0.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'commander'
  spec.add_runtime_dependency 'colorize'
  
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
