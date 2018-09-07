require 'liquid'
require 'faker'

module TestFakerFilter
  def fake(input)
    # Not nice, but I don't know better way.
    eval "Faker::#{input}" # rubocop:disable Security/Eval,Style/EvalWithLocation
  end
end
