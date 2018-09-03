require 'simplecov'
SimpleCov.start

require "minitest/autorun"
require 'minitest/reporters/json_reporter'
require 'minitest/reporters/junit_reporter'
require 'webmock/minitest'

class Minitest::Test
  def assert_not_nil(*args)
    refute_nil(*args)
  end

  def assert_not_empty(*args)
    refute_empty(*args)
  end

  def assert_not(*args)
    refute(*args)
  end

end

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter

Minitest::Reporters.use! [ Minitest::Reporters::SpecReporter.new(color: true), Minitest::Reporters::JUnitReporter.new("test/reports", true, single_file: true) ]
