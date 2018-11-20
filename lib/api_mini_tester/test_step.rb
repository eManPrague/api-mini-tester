require 'httparty'
require 'liquid'
require 'hash_parser'
require 'uri'
require 'json'
require 'distribution'
require_relative 'test_faker_filter'

module ApiMiniTester
  class TestStep

    include HTTParty

    SUPPORTED_METHODS = %i[ get post put delete ].freeze
    SUPPORTED_RANDOM_DISTRIBUTION = %w[ static norm uniform ].freeze

    attr_accessor :name, :input, :output
    attr_reader :results, :sleeps, :method, :uri

    def initialize(base_uri, step, context = nil, data = nil, defaults = nil)
      step = step.deep_merge!(defaults) do |key, this_val, other_val|
        if this_val.nil?
          other_val
        elsif this_val.is_a?(Array)
          (this_val + other_val)
        else
          this_val
        end
      end if defaults

      Liquid::Template.register_filter(::TestFakerFilter)
      @context = context
      uri_template = Liquid::Template.parse([base_uri, step['uri']].join("/"), error_mode: :strict)
      @name = step['name']
      @sleeps = step['sleep']

      @uri = uri_template.render(
        {'context' => context, 'data' => data},
        { strict_variables: true })
      @method = step['method'].downcase.to_sym

      input_template = Liquid::Template.parse(step['input'].to_yaml.to_s, error_mode: :strict)
      @input = YAML.load(
        input_template.render({'context' => context, 'data' => data}, { strict_variables: true }))

      output_template = Liquid::Template.parse(step['output'].to_yaml.to_s, error_mode: :strict)
      @output = YAML.load(
        output_template.render({'context' => context, 'data' => data}, { strict_variables: true }))

      @results = { name: step['name'], desc: step['desc'], status: [], headers: [], body: [], url: [], method: [], timing: [] }
    end

    def valid?
      return false if uri.nil? || uri.empty?

      return false unless URI.parse(uri) rescue false
      return false unless SUPPORTED_METHODS.include? method
      return false if @name.nil? || @name.empty?

      true
    end

    def content_type
      @input['content_type'] || 'application/json'
    end

    def headers
      @input['header'] = {} unless @input['header']
      @input['header']['Content-type'] = content_type if content_type == 'application/json'
      @input['header']
    end

    def body
      case content_type
      when 'application/x-www-form-urlencoded'
        body_to_form_data
      when 'multipart/form-data'
        body_to_form_data
      else
        @input["body"].to_json
      end
    end

    def body_to_form_data
      body = {}
      @input["body"].each do |item|
        body[item['name']] = item['value'] if item['type'] == 'input'
        body[item['name']] = File.open(item['value'], 'r') if item['type'] == 'file'
      end
      body
    end

    def test_headers
      @output['header']
    end

    def test_body
      @output['body']
    end

    def test_status
      @output['status']
    end

    def test_timing
      @output['timing']
    end

    def run_step
      if sleeps
        step_sleep(sleeps['before']) if sleeps['before']
      end

      @timing = Time.now
      case method
      when :get
        response = HTTParty.get(uri, headers: headers)
      when :post
        response = HTTParty.post(uri, headers: headers, body: body)
      when :put
        response = HTTParty.put(uri, headers: headers, body: body)
      when :delete
        response = HTTParty.delete(uri, headers: headers)
      when :patch
        response = HTTParty.patch(uri, headers: headers, body: body)
      else
        raise "Unknown HTTP method: #{method}"
      end
      @timing = Time.now - @timing

      if sleeps
        step_sleep(sleeps['after']) if sleeps['after']
      end

      add_result :url, { result: true, desc: "Url: #{uri}" }
      add_result :method, { result: true, desc: "Method: #{method}" }

      assert_status(response.code, test_status)
      assert_headers(response.headers, test_headers)
      assert_body(response.parsed_response, test_body)
      assert_timing(@timing, test_timing)

      [ results, response ]
    end

    def print_results
      @results.each do |line|
        puts line
      end
    end

    def add_result(section, result)
      @results[section] << result
    end

    def step_sleep(params)
      params['distribution'] = 'static' unless SUPPORTED_RANDOM_DISTRIBUTION.include?(params['distribution'])

      t = begin
        case params['distribution']
        when 'static'
          params['value']
        when 'norm'
          Distribution::Normal.rng(params['mean'], params['sigma'], srand).call
        when 'uniform'
          Random.new.rand(params['max'] - params['min']) + params['min']
        end
      end
      puts "Sleeping for #{t} seconds"
      sleep(t.to_f.abs) if t
    end

    def assert_timing(runtime, limit = nil)
      limit ||= Float::INFINITY
      add_result :timing, { result: (runtime < limit),
                            name: "Request time < #{limit}",
                            desc: "Expected request time #{limit}, real time #{runtime}",
                            exp: limit, real: runtime }
    end

    def assert_status(response, output)
      add_result :status, { result: (response == output),
                            name: "Response code == #{output}",
                            desc: "Expected response #{output}, got response #{response}",
                            exp: output, real: response }
    end

    def assert_headers(response, output)
      return if output.nil?

      output.each do |k, v|
        add_result :headers, { result: (v == response[k]),
                               name: "Header value: #{k} == #{v}",
                               desc: "Header #{k} expected: #{v}, got #{response[k]}",
                               exp: v, real: response[k] }
      end
    end

    def assert_body(response, output)
      if output.instance_of?(Hash)
        hash_diff(output, response)
      elsif output.instance_of?(Array)
        array_diff(output, response)
      end
    end

    def array_diff(a, b, path = nil, section = :body)
      a.each do |a_item|
        if b.nil?
          add_result section, { result: false,
            name: "Response boby value: #{[path].join(".")}",
            desc: "Assert #{[path].join(".")} is empty" }
        elsif a_item.instance_of?(Hash)
          found = false
          b.each do |b_item|
            matching = true
            a_item.each_key do |k, v|
              matching = (b_item[k] == a_item[k]) if matching
            end
            found = true if matching
          end
          add_result section, { result: found,
                                name: "Response body value: #{[path].join(".")}",
                                desc: "Assert #{[path].join(".")} #{found ? 'contains' : 'does not contains'} #{a_item}" }
        elsif a_item.instance_of?(Array)
          # TODO: Add support for array of array it isn't so needed to compate so deep structures
        else
          add_result section, { result: b.include?(a_item),
                                name: "Response boby value: #{[path].join(".")}",
                                desc: "Assert #{[path].join(".")} #{b.include?(a_item) ? 'contains' : 'does not contains'} #{a_item}" }
        end
      end
    end

    def hash_diff(a, b, path = nil, section = :body)
      return nil if a.nil? || b.nil?

      a.each_key do |k, v|
        current_path = [path, k].join('.')
        if b[k].nil?
          add_result section, { result: false,
                                name: "Reponse value: #{[path, k].join(".")}",
                                desc: "Missing #{current_path}" }
        elsif v.instance_of?(Hash)
          hash_diff(a[k], b[k], current_path, section)
        elsif v.instance_of?(Array)
          array_diff(a[k], b[k], current_path, section)
        else
          add_result section, { result: (a[k] == b[k]),
                                name: "Reponse body value: #{[path, k].join(".")}",
                                desc: "Assert #{[path, k].join(".")}: #{a[k]} #{a[k] == b[k] ? '==' : '!='} #{b[k]}" }
        end
      end
    end
  end
end

class Hash
  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |current_key, other_value|
      this_value = self[current_key]

      self[current_key] = begin
        if   this_value.is_a?(Hash) && other_value.is_a?(Hash)
          this_value.deep_merge(other_value, &block)
        elsif block_given? && key?(current_key)
          block.call(current_key, this_value, other_value) # rubocop:disable Performance/RedundantBlockCall
        else
          other_value
        end
      end
    end

    self
  end
end
