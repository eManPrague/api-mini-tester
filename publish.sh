#!/bin/bash

bundle install
gem build api_mini_tester.gemspec
gem install api_mini_tester-${CI_COMMIT_TAG}.gem
