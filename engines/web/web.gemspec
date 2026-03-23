# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "web"
  s.version     = "0.1.0"
  s.summary     = "Web interface for Rails Whey App"
  s.authors     = [ "Rails Whey App" ]

  s.files = Dir["{app,config,lib}/**/*", "web.gemspec"]
  s.require_paths = [ "lib" ]

  s.add_dependency "rails", "~> 8.1"
  s.add_dependency "importmap-rails"
  s.add_dependency "turbo-rails"
  s.add_dependency "stimulus-rails"
end
