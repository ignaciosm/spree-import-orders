# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_import_orders'
  s.version     = '3.0.1'
  s.summary     = 'spree_import_orders ... imports orders. From a CSV file via Spree Admin interface'
  s.description = 'TODO: Add (optional) gem description here'
  s.required_ruby_version = '>= 2.0.0'

  s.authors   = ["Rohit Agarwal"]
  s.email     = 'rohitagarwal.2k6@gmail.com'
  s.homepage  = 'http://www.github.com/rohitnick'
  s.date      = "2016-03-29"

  #s.files       = `git ls-files`.split("\n")
  #s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.0.1'

  s.add_development_dependency 'capybara', '~> 2.4'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.5'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 3.1'
  s.add_development_dependency 'sass-rails', '~> 5.0.0.beta1'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
