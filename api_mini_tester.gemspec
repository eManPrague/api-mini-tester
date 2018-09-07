Gem::Specification.new do |s|
  s.name        = 'api_mini_tester'
  s.version     = '0.1.5'
  s.date        = '2018-09-07'
  s.summary     = "Runs automated REST API based on YAML definition"
  s.description = "Runs automated REST API based on YAML definition"
  s.authors     = ["Jindrich Skupa (@eMan)"]
  s.email       = 'jindrich.skupa@gmail.com'
  s.files       = ["lib/api_mini_tester.rb",
                   "lib/api_mini_tester/test_suite.rb",
                   "lib/api_mini_tester/test_scenario.rb",
                   "lib/api_mini_tester/test_step.rb",
                   "lib/api_mini_tester/test_formatter.rb",
                   "lib/api_mini_tester/test_faker_filter.rb"]
  s.homepage    = 'http://rubygems.org/gems/api_mini_tester'
  s.license     = 'MIT'
  s.add_runtime_dependency 'builder', '~> 3.0', '>= 3.0.4'
  s.add_runtime_dependency 'faker', '~> 1.8', '>= 1.8.7'
  s.add_runtime_dependency 'hash_parser', '~> 0.0', '>= 0.0.2'
  s.add_runtime_dependency 'httparty', '~> 0.16', '>= 0.16.0'
  s.add_runtime_dependency 'liquid', '~> 4.0', '>= 4.0.0'
  s.add_development_dependency 'minitest', '~> 5.11', '>= 5.11.3'
  s.add_development_dependency 'minitest-reporters-json_reporter', '~> 1.0', '>= 1.0.0'
  s.add_development_dependency 'nexus', '~> 1.4', '>= 1.4.0'
  s.add_development_dependency 'rubocop', '~> 0.58', '>= 0.58.2'
  s.add_development_dependency 'simplecov', '~> 0.16', '>= 0.16.1'
  s.add_development_dependency 'webmock', '~> 3.4', '>=3.4.2'
end
