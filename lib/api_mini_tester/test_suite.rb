require 'yaml'
require_relative 'test_scenario'
require_relative 'test_formatter'

module ApiMiniTester
  class TestSuite

    attr_reader :base_uri, :scenarios, :data, :results, :defaults

    def initialize(suite_def)
      if suite_def.is_a?(String)
        @test = YAML.load(File.open(suite_def))
      elsif suite_def.is_a?(Hash)
        @test = suite_def
      end
      setup
    end

    def valid?
      return false if base_uri.nil? || base_uri.empty?
      return false if scenarios.nil? || scenarios.empty?

      true
    end

    def setup
      @base_uri = @test['settings']['baseurl']
      @scenarios = @test['tests']
      @data = @test['data']
      @defaults = @test['defaults']
      @results = {name: @test['name'], desc: @test['desc'], scenarios: []}
    end

    def run_scenarios
      scenarios.each do |scenario|
        runner = TestScenario.new(base_uri, scenario, data, defaults)
        runner.run_scenario
        @results[:scenarios] << runner.results
      end
      @results
    end

    def print_results(format)
      formatter = TestFormatter.new(results)
      formatter.send("to_#{format}")
    end

  end
end
