# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amazon-drs/version'

Gem::Specification.new do |spec|
  spec.name          = "amazon-drs"
  spec.version       = AmazonDrs::VERSION
  spec.authors       = ["Code Ass"]
  spec.email         = ["aycabta@gmail.com"]

  spec.summary       = %q{amazon-drs is for Amazon Dash Replenishment Service}
  spec.description   = %Q{amazon-drs is for Amazon Dash Replenishment Service.\nYou can use this after authorized by Login with Amazon.}
  spec.homepage      = "https://github.com/aycabta/amazon-drs"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f| f.match(%r{^(test|spec|features)/}) end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "webmock"
end
