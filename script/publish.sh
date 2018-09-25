#!/bin/bash

bundle install
gem build api_mini_tester.gemspec
gem install api_mini_tester-${CI_COMMIT_TAG}.gem
gem nexus api_mini_tester-${CI_COMMIT_TAG}.gem --url https://nexus.eman.cz/repository/eman-gems/ --credential "$NEXUS_USER:$NEXUS_PASSWORD"
