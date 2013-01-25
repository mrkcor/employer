# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'employer/version'

Gem::Specification.new do |gem|
  gem.name          = "employer"
  gem.version       = Employer::VERSION
  gem.authors       = ["Mark Kremer"]
  gem.email         = ["mark@without-brains.net"]
  gem.summary       = %q{Job processing made easy}
  gem.homepage      = "https://github.com/mkremer/employer"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rspec"
end
