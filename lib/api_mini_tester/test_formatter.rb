require 'builder'
require 'socket'

module ApiMiniTester
  class TestFormatter

    RESULT_SECTIONS = %i[status headers body timing].freeze
    SECTION_TRANSLATE = {
      status: "Status",
      headers: "Headers",
      body: "Body",
      timing: "Timing"
    }.freeze

    attr_accessor :results

    def initialize(results)
      @results = results
    end

    def to_json
      clean_up_infinity.to_json
    end

    def to_yaml
      clean_up_infinity.to_yaml
    end

    def to_junit_xml
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct! :xml, encoding: "UTF-8"
      xml.testsuites do
        results[:scenarios].each do |scenario|
          xml.testsuite name: scenario[:name],
                        timestamp: timestamp,
                        hostname: hostname,
                        tests: tests_in_scenario(scenario),
                        skipped: 0,
                        failures: failed_in_scenario(scenario),
                        errors: 0,
                        time: time_in_scenario(scenario) do
            scenario[:steps].each do |step|
              classname = name_to_camelcase(step[:name])
              RESULT_SECTIONS.each do |section|
                step[section].each do |s|
                  xml.testcase classname: classname,
                              name: s[:name],
                              time: step_timing(step),
                              file: "./#{classname}.rb"  do
                    s[:result] ? nil : xml.failure(message: s[:desc])
                  end
                end
              end
            end
          end
        end
      end
    end

    def timestamp
      Time.now.strftime("%FT%T%:z")
    end

    def scenarios_count
      results[:scenarios].size
    end

    def steps_count(scenario)
      scenario[:steps].size
    end

    def test_count(step)
      count = 0
      [:status, :headers, :body, :timing].each do |section|
        count += step[section].size
      end
      count
    end

    def tests_in_scenario(scenario)
      count = 0
      scenario[:steps].each do |step|
        count += test_count(step)
      end
      count
    end

    def time_in_scenario(scenario)
      time = 0.0
      scenario[:steps].each do |step|
        time += step[:timing].first[:real]
      end
      time
    end

    def failed_in_scenario(scenario)
      count = 0
      scenario[:steps].each do |step|
        [:status, :headers, :body, :timing].each do |section|
          count += step[section].map { |res| res[:result] }.select(&:!).size
        end
      end
      count
    end

    def hostname
      Socket.gethostname
    end

    def name_to_camelcase(name)
      name.gsub(/[[:space:]]+/, '_').downcase.gsub(/(?:^|_)([a-z])/) { $1.upcase }
    end

    def step_timing(step)
      step[:timing].first ? step[:timing].first[:real] : 0
    end

    def clean_up_infinity
      res = results.dup
      res[:scenarios].each do |scenario|
        scenario[:steps].each do |step|
          step[:timing].each do |timing|
            timing[:exp] = "Not Specified" if timing.is_a?(Hash) && timing[:exp] && timing[:exp] == Float::INFINITY
          end
        end
      end
      res
    end

    def array_in(array)
      list = ''
      array.each do |item|
        if item.instance_of?(Array)
          list << array_in(item)
        elsif item.instance_of?(Hash)
          list << hash_in(item)
        end
      end
      list
    end

    def hash_in(hash)
      list = ''
      hash.each do |k, v|
        if v.instance_of?(Hash)
          list << hash_in(v)
        elsif v.instance_of?(Array)
          list << array_in(v)
        elsif k == :result
          list << (v ? '.' : 'E')
        end
      end
      list
    end

    def to_simple
      hash_in results
    end

    def md_section_header(header, desc, level)
      output = []
      output << "#{'#' * level} #{header}"
      output << ""
      if desc
        output << "Desc: #{desc}"
        output << ""
      end
      output
    end

    def md_step_header(step)
      output = []
      output.push(*md_section_header(step[:name], step[:desc], 3))
      output.push(*md_section_header("Call", nil, 4))
      step[:url].each do |url|
        output << "* #{url[:desc]}"
      end
      step[:method].each do |method|
        output << "* #{method[:desc]}"
      end
      output << ""
      output
    end

    def md_section_content(step, section)
      output = []
      output << md_section_header(SECTION_TRANSLATE[section], nil, 4)
      step[section].each do |status|
        output << "* `#{status[:result]}`: #{status[:desc]}"
      end
      output << ""
      output
    end

    def to_markdown
      output = []
      output << md_section_header(results[:name], results[:desc], 1)
      results[:scenarios].each do |scenario|
        output << md_section_header(scenario[:name], scenario[:desc], 2)
        scenario[:steps].each do |step|
          output.push(*md_step_header(step))
          RESULT_SECTIONS.each do |section|
            output.push(*md_section_content(step, section))
          end
        end
      end
      output.join("\n")
    end
  end
end
