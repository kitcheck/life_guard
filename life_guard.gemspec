# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'life_guard/version'

Gem::Specification.new do |spec|
  spec.name          = "life_guard"
  spec.version       = LifeGuard::VERSION
  spec.authors       = ["Jon Calvert"]
  spec.email         = ["jonathan.calvert@kitcheck.com"]

  spec.summary       = %q{Manage the (active_record connection) pool}
  spec.description   = %q{Manage the (active_record connection) pool via Rack middleware}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("activerecord", ">= 4.0")

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "sqlite3", ">= 1.3.4"
  spec.add_development_dependency "rack", ">= 1.6.4"
  spec.add_development_dependency "mocha", "1.1.0"
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rails', "= 4.2.3"

end
