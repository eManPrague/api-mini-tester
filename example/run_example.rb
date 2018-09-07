require 'api_mini_tester'
require 'webmock'

include WebMock::API

WebMock.enable!

stub_request(:get, "https://api.example.com/items")
.with(
  headers: {
    'Content-Type' => 'application/json',
    'From' => 'me@you.it',
    'Count' => '8'
 })
.to_return(status: 200, body: "", headers: { server: 'nginx' })

suite = ApiMiniTester::TestSuite.new("example/test/single.example.yml")
suite.run_scenarios

File.open("example/output/output.json", 'w') { |file| file.write(suite.print_results(:json)) }
File.open("example/output/output.yml", 'w') { |file| file.write(suite.print_results(:yaml)) }
File.open("example/output/output.md", 'w') { |file| file.write(suite.print_results(:markdown)) }
File.open("example/output/output.xml", 'w') { |file| file.write(suite.print_results(:junit_xml)) }
File.open("example/output/output.txt", 'w') { |file| file.write(suite.print_results(:simple)) }
puts suite.print_results(:simple)

