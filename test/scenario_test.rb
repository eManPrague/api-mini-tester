require_relative 'test_helper'
require 'api_mini_tester'
require 'json'

class ScenarioTest < Minitest::Test
  def setup
    @context = []
    @suite = YAML.load(File.open('example/test/single.example.yml'))
    @base_uri = @suite['settings']['baseurl']
    @data = @suite['data']
    @scenario = ApiMiniTester::TestScenario.new(@base_uri, @suite['tests'].first, @data)
    stub_request(:get, "https://api.example.com/items")
    .with(
      headers: {
        'Content-Type' => 'application/json',
        'From' => 'me@you.it'
      })
    .to_return(status: 200, body: "", headers: {})
    @scenario.run_scenario
  end

  def test_scenario
    assert_not_nil @scenario.scenario
    assert_not_nil @scenario.scenario['steps']
    assert @scenario.scenario['steps'].is_a?(Array)
    assert_not @scenario.scenario['steps'].empty?
    assert_not_nil @scenario.name
    assert_not @scenario.name.empty?
    assert_not_nil @scenario.base_uri
    assert_not @scenario.base_uri.empty?
    assert @scenario.valid?, "Invalid scenario"
  end
end
