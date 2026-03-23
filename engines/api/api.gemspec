# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "api"
  s.version     = "0.1.0"
  s.summary     = "API interface for Rails Whey App"
  s.authors     = [ "Rails Whey App" ]

  s.files = Dir["{app,config,lib}/**/*", "api.gemspec"]
  s.require_paths = [ "lib" ]

  s.add_dependency "rails", "~> 8.1"
  s.add_dependency "jbuilder"
end
