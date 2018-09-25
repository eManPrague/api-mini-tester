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
        suite['tests'][0]['steps'] = steps(collection['item'])
        suite.to_yaml
      end

      def suite_base
        @suite_base ||= {
          'name' => name,
          'desc' => "Imported from postman collection: #{name}",
          'settings' => {
            'baseurl' => baseurl(collection['item'])
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

      def max_common_url(url1, url2)
        return "" unless url1 && url2
        index = 0
        index += 1 while url1[index] && url2[index] && url1[index] == url2[index]
        return "" if index == 0
        url1[0..(index - 1)][0..(url1.rindex('/') - 1)]
      end

      def baseurl(items)
        base = ''
        items.each do |item|
          if item['item']
            item_url = baseurl(item['item']) 
          elsif item['request']
            item_url = item['request']['url']['raw']
          end
          base = max_common_url(base, item_url)
        end
        base
      end

      def steps(items)
        res = []
        items.each do |item|
          if item['item']
            res << steps(item['item'])
          elsif item['request']
            res << step(item)
          end
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
        begin
          body ? JSON.parse(body) : {}
        rescue JSON::ParserError
          {}
        end
      end

      def step(item)
        res = {
          'step' => item['name'],
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
