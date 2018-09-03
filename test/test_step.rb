require_relative 'test_helper'
require 'api_mini_tester'
require 'json'

class StepTest < Minitest::Test

  # The `setup` method is run before every test.
  def setup
    @context = []
    @suite = YAML.load(File.open('example/test/get.example.yml'))
    @base_uri = @suite['settings']['baseurl']
    @data = @suite['data']
    @scenario = @suite['tests'].first
  end

  def setup_test(step)
    in_headers = @step.input['header'] ? {'Content-Type' => 'application/json'}.merge(@step.input['header']) : {'Content-Type' => 'application/json'}
    out_headers = @step.output['header'] ? {'Content-Type' => 'application/json'}.merge(@step.output['header']) : {'Content-Type' => 'application/json'}
    stub_request(step['method'].downcase.to_sym, @step.uri)
    .with(
      headers: in_headers,
      body: step['method'].downcase.to_sym == :get ? nil : /.*/
    )
    .to_return(
      status: step['output']['status'],
      body: step['output']['body'].to_json,
      headers: out_headers
    ) if @step.input['content_type'] != "multipart/form-data"
  end

  def test_all_example
    @scenario['steps'].each do |step|
      @step = ApiMiniTester::TestStep.new(@base_uri, step, @context, @data)
      setup_test(step)
      call_basic_test
    end
  end

  def call_basic_test
    skip 'Content-type: multipart/form-data is not supported by webmock' if @step.input['content_type'] == "multipart/form-data"
    assert @step.valid?, "Step definition is invalid"
    @step_result, context = @step.run_step
    @context << context
    assert_not_nil @step_result, "Sucess step call: #{@step.name}"
    assert_not_nil context, "Returns context #{@step.name}"
    basic_test_meta
    basic_test_headers
    basic_test_status
    basic_test_body
  end

  def basic_test_meta
    url = @step_result[:url].first
    assert_equal true, url[:result], true
    assert_equal "Url: #{@step.uri}", url[:desc], "url: #{url[:desc]}"
  end

  def basic_test_headers
    headers = @step_result[:headers]
    headers.each do |header|
      assert_equal true, header[:result], "header: #{header[:desc]}"
    end
  end

  def basic_test_status
    status = @step_result[:status].first
    assert_equal true, status[:result], "status: #{status[:desc]}"
  end

  def basic_test_body
    bodies = @step_result[:body]
    bodies.each do |body|
      assert_equal true, body[:result], "body: #{body[:desc]}"
    end
  end

end
