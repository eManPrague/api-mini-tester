require_relative 'test_helper'
require 'api_mini_tester'
require 'json'

class SuiteTest < Minitest::Test
  def setup
    @context = []
    @suite = ApiMiniTester::TestSuite.new("example/test/single.example.yml")
    stub_request(:get, "https://api.example.com/items")
    .with(
      headers: {
        'Content-Type' => 'application/json',
        'From' => 'me@you.it',
        'Count' => '8',
        'User-Agent' => 'Api-Mini-Tester-Agent'
      })
    .to_return(status: 200, body: "", headers: {})
    @suite.run_scenarios
  end

  def test_suite
    assert_not_empty @suite.print_results(:json)
    assert_not_empty @suite.print_results(:junit_xml)
    assert_not_empty @suite.print_results(:yaml)
    assert_not_empty @suite.print_results(:simple)
    assert_not_empty @suite.print_results(:markdown)
    assert @suite.valid?, "Invalid suite"
  end
end
