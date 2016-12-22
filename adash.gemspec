# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'adash/version'

Gem::Specification.new do |spec|
  spec.name          = "adash"
  spec.version       = Adash::VERSION
  spec.authors       = ["Code Ass"]
  spec.email         = ["aycabta@gmail.com"]

  spec.summary       = %q{Adash is a Dash Replenishment Service CLI client}
  spec.description   = %Q{Adash is a Dash Replenishment Service CLI client.\nYou will login with OAuth (Login with Amazon) and replenish items.}
  spec.homepage      = "https://github.com/aycabta/adash"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f| f.match(%r{^(test|spec|features)/}) end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "launchy", "~> 2.5"
end
