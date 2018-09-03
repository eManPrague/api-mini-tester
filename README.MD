# api-mini-tester

Gem to run API (REST/JSON) test scenarios defined by YAML file with many output formats. 
Just create simple API calls definition in YAML with output validations. 
Use common data section, send multipart content and use previous reponses in next call.

## Badges

[![Gem Version](https://badge.fury.io/rb/api_mini_tester.svg)](https://badge.fury.io/rb/api_mini_tester)
[![Build Status](https://travis-ci.org/eManPrague/api-mini-tester.svg?branch=master)](https://travis-ci.org/eManPrague/api-mini-tester)

## Install

```bash
gem install api_mini_tester
```

or with bundler add into `Gemfile`

```bash
gem 'api_mini_tester'
```

then run

```bash
bundle install
```

## Test suite

`single.example.yml`:

```yaml
name: "GET example"
desc: "Test suite GET example"
settings:
  baseurl: "https://api.example.com"
data:
  from: me@you.it
tests:
  - name: "Test scenario 1"
    steps:
    - step: 0
      name: "GET some list"
      desc: "Longer description"
      uri: "items"
      method: GET
      input:
        header:
          From: "{{ data['from'] }}"
        body: nil
      output:
        header:
          server: "nginx"
        status: 200
        body:
          id: 1
          name: "Item 1"
```

## Example run

`run_test.rb`:

```ruby
require 'api_mini_tester'

suite = ApiMiniTester::TestSuite.new("tests/test.example.yml")
result = suite.run_scenarios

puts suite.print_results(:markdown)
puts suite.print_results(:yaml)
puts suite.print_results(:json)
puts suite.print_results(:junit_xml)
puts suite.print_results(:simple)
```

```bash
ruby run_test.rb
```

## Outputs

* markdown
* yaml
* json
* simple
* JUnit XML

### Example outputs

markdown:

```markdown
# GET example

Desc: Test suite GET example

## Test scenario 1

### GET some list

Desc: Longer description

#### Call

* Url: https://api.example.com/items
* Method: get

#### Status

* `true`: Expected response 200, got response 200

#### Headers

* `true`: Header server expected: nginx, got nginx

#### Body


#### Timing

* `true`: Expected request time Infinity, real time 0.010791
```

simple

```text
......
```

other examples are in `example` directory

## Integration

Example integration with Gitlab or Viper follows.

### Test code

`api-mini-test.rb`:

```ruby
require 'api_mini_tester'

suite = ApiMiniTester::TestSuite.new("test.example.yml")
suite.run_scenarios

File.open("result/api-test.json", 'w') { |file| file.write(suite.print_results(:json)) }
File.open("result/junit.xml", 'w') { |file| file.write(suite.print_results(:junit_xml)) }
puts suite.print_results(:simple)
```

### Gitlab CI Integration

Example for Viper push and JUnit output integration to Gitlab via GitLab CI.

```yaml
api test:
  stage: api tests
  script:
    - gem install api_mini_tester
    - ruby api-mini-test.rb
  artifacts:
    reports:
      junit: result/junit.xml
  only:
    - branches
```

### Viper integration

1. Obtain Viper API token
2. Save test output into json file
3. Push results into Viper

```bash
curl -X POST --header "X-Api-Token:$VIPER_API_TOKEN" \
  --header "Content-Type:application/json" \
  --header "X-Api-Branch-Name:$CI_COMMIT_REF_NAME" \
  --header "X-Api-Pipeline-Id:$CI_PIPELINE_ID" \
  --data @result/test.get.example.json \
  --header "X-Api-Ref:$CI_COMMIT_REF_SLUG" \
  "https://viper.dev.eman.cz/api/tests?service=apiminitester"
```
