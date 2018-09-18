require_relative 'test_step'

module ApiMiniTester
  class TestScenario

    attr_reader :base_uri, :scenario, :data, :results, :name, :defaults

    def initialize(base_uri, scenario, data, defaults)
      @base_uri = base_uri
      @scenario = scenario
      @data = data
      @name = scenario['name']
      @defaults = defaults
      @results = {name: @name, desc: scenario['desc'], steps: []}
    end

    def valid?
      return false if scenario.nil? || scenario['steps'].nil?
      return false unless scenario['steps'].is_a?(Array) || scenario['steps'].empty?
      return false if name.nil? || name.empty?
      return false if base_uri.nil? || base_uri.empty?

      true
    end

    def add_result(result)
      @results.steps << result
    end

    def print_results
      @results.each do |line|
        puts line
      end
    end

    def run_scenario
      @context = []
      scenario['steps'].each do |step|
        step = TestStep.new(base_uri, step, @context, data, defaults)
        step_result, context = step.run_step
        @results[:steps] << step_result
        @context << context
      end
    end
  end
end
