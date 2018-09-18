require 'json'
require 'yaml'

module ApiMiniTester
  module Import
    class Postman
      attr_reader :collection

      def initialize(json_collection)
        @collection = JSON.parse json_collection
      end

      def to_yaml
        suite = suite_base
        suite['tests'][0]['steps'] = steps
        suite.to_yaml
      end

      def suite_base
        @suite_base ||= {
          'name' => name,
          'desc' => "Imported from postman collection: #{name}",
          'settings' => {
            'baseurl' => baseurl
          },
          'tests' => [
            {
              'name' => "Test scenario based on postman collection #{name}",
              'steps' => []
            }
          ]
        }
      end

      def name
        collection['info']['name']
      end

      def baseurl
        @base ||= begin
          base = collection['item'][0]['request']['url']['raw']
          collection['item'].each do |item|
            item_url = item['request']['url']['raw']
            index = 0
            index += 1 while base[index] && item_url[index] && base[index] == item_url[index]
            base = base[0..(index - 1)][0..(base.rindex('/') - 1)]
          end
          base
        end
        @base
      end

      def steps
        res = []
        index = 0
        collection['item'].each do |item|
          res << step(item, index)
          index += 1
        end
        res
      end

      def step_uri(uri)
        uri.gsub("#{@base}/", "")
      end

      def step_header(header)
        res = {}
        header.each do |h|
          res[h['key']] = h['value']
        end
        res
      end

      def step_body(body)
        body ? JSON.parse(body) : {}
      end

      def step(item, index)
        res = {
          'step' => index,
          'name' => item['name'],
          'method' => item['request']['method'],
          'uri' => step_uri(item['request']['url']['raw']),
          'input' => {
            'header' => step_header(item['request']['header']),
            'body' => step_body(item['request']['body']['raw'])
          },
          'output' => {
            'header' => {},
            'body' => {}
          }
        }
        res
      end
    end
  end
end
