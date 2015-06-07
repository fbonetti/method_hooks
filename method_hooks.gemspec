# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'method_hooks/version'

Gem::Specification.new do |spec|
  spec.name          = "method_hooks"
  spec.version       = MethodHooks::VERSION
  spec.authors       = ["Frank Bonetti"]
  spec.email         = ["frank.r.bonetti@gmail.com"]
  spec.summary       = %q{Rails-style method hooks for plain old Ruby objects}
  spec.description   = %q{Rails-style method hooks for plain old Ruby objects}
  spec.homepage      = "https://github.com/fbonetti/method_hooks"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
