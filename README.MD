# api-mini-tester

Gem to run API (REST/JSON) test scenarios defined by YAML file with many output formats.
Just create simple API calls definition in YAML with output validations.
Use prepared static or [fake](http://rubygems.org/gems/faker)/ or [cz_fake](http://rubygems.org/gems/cz_faker) data, send multipart content or use previous reponses in calls.

## Badges

[![Gem Version](https://badge.fury.io/rb/api_mini_tester.svg)](https://badge.fury.io/rb/api_mini_tester)
[![Build Status](https://travis-ci.org/eManPrague/api-mini-tester.svg?branch=master)](https://travis-ci.org/eManPrague/api-mini-tester)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/eManPrague/api-mini-tester/blob/master/LICENSE)
[![Documentation](https://img.shields.io/badge/docs-in%20progress-lightgrey.svg)](https://github.com/eManPrague/api-mini-tester/blob/master/README.MD)


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
# default for each request, will be merged into step definition before expansion
defaults:
  input:
    header:
      User-Agent: 'Api-mini-tester-agent'
tests:
  - name: "Test scenario 1"
    steps:
    - step: 0
      name: "GET some list"
      desc: "Longer description"
      uri: "items"
      method: GET
      sleep:
        # sleep before call for 10s
        before:
          value: 10
        # sleep after call for random time - normal distribution with params
        # static: value
        # norm: mean, sigma
        # uniform: min, max
        after:
          distribution: norm
          mean: 5
          sigma: 1
      input:
        header:
          # use value from global data section
          From: "{{ data['from'] }}"
          # use Faker, choose method with params without 'Faker' module namespace and use filter fake
          Count: "{{ 'Number.between(1, 10)' | fake }}"
        body: nil
      output:
        # assert headers
        header:
          server: "nginx"
        # assert http return code
        status: 200
        # assert body content
        body:
        - id: 1
          name: "Item 1"
    - step: 1
      name: "Get item detail"
      desc: "Longer description"
      # use data returned in some previous step
      uri: "items/{{ context[0].first['id'] }}"
      method: GET
      input:
        header:
          From: "{{ data['from'] }}"
        body:
      output:
        header: nil
        body:
          name: "Item 1"
        status: 200
    - step: 2
      name: "Update item detail"
      desc: "Longer description"
      # use data returned in some previous step
      uri: "items/{{ context[0].first['id'] }}"
      method: PUT
      input:
        header:
          From: "{{ data['from'] }}"
        body:
          # use CzFaker, choose method with params without 'CzFaker' module namespace and use filter cz_fake
          name: "{{ 'Name.name(:female)' | cz_fake }}"
      output:
        header: nil
        body: nil
        status: 200
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

## Debug output

For debug output into `debug.json` file create TestSuite with debug flag.

```ruby
suite = ApiMiniTester::TestSuite.new("tests/test.example.yml", true)
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

## CLI tools

### api_mini_tester

Runs test suite from command line.

Usage: `api_mini_tester [--debug] [input_file.yml] [output_format]`

```bash
$ api_mini_tester --debug scenarios/sc01.yml simple
....E..
```

### postman2minitester

Converts Postman JSON collection into API mini tester YAML test specification.

Usage: `api_mini_tester [input_file.json] [output_file.yaml]`

```bash
$ postman2minitester postman.json postman.yml
```

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

### Run YAML definition directly

```bash
# api_mini_tester <input_file.yaml> [output_format: simple, json, yaml, markdown, junit_xml, ...]
api_mini_tester api-mini-tester-definition.yaml json
```

### Postman collection import

Conversion from Postman collection into YAML definition is more accuracy.

```bash
# postman2minitester <input_file.json> <output_file.yaml>
postman2minitester postman.collection.json api-mini-tester-definition.yaml
```
