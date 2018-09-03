require_relative 'test_helper'
require_relative 'suite_test'
require 'api_mini_tester'
require 'json'

class SuiteHashTest < SuiteTest
  def setup
    @context = []
    suite_hash = YAML.load(File.open("example/test/single.example.yml"))
    @suite = ApiMiniTester::TestSuite.new(suite_hash)
    stub_request(:get, "https://api.example.com/items")
    .with(
      headers: {
        'Content-Type' => 'application/json',
        'From' => 'me@you.it'
      })
    .to_return(status: 200, body: "", headers: {})
    @suite.run_scenarios
  end
end
