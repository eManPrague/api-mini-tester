require_relative 'test_helper'
require_relative 'test_step'
require 'api_mini_tester'
require 'json'

class ArrayGetSteptTest < StepTest

  # The `setup` method is run before every test.
  def setup
    @context = []
    @suite = YAML.load(File.open('example/test/get.array.example.yml'))
    @base_uri = @suite['settings']['baseurl']
    @data = @suite['data']
    @scenario = @suite['tests'].first
  end

end
