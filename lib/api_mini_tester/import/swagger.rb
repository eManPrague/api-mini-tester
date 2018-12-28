require 'json'
require 'yaml'

module ApiMiniTester
  module Import
    class Swagger
      attr_reader :collection

      def initialize(swagger)
        ''
      end

      def to_yaml
        ''
      end

      def suite_base
        @suite_base ||= {
          name: name,
          desc: "Imported from swagger definition: #{name}",
          settings: {
            baseurl: ''
          },
          tests: [
            {
              name: "Test scenario based on swagger definition #{name}",
              steps: []
            }
          ]
        }
      end

      def name
        ''
      end

      def baseurl
        ''
      end

      def steps
        ''
      end

      def step_uri(uri)
        ''
      end

      def step_header(header)
        ''
      end

      def step_body(body)
        ''
      end

      def step(item)
        res = {
          step: '',
          name: '',
          method: '',
          uri: '',
          input: {
            header: {},
            body: {}
          },
          output: {
            header: {},
            body: {}
          }
        }
        res
      end
    end
  end
end
