require 'liquid'
require 'faker'
require 'cz_faker'

module TestFakerFilter
  def fake(input)
    # Not nice, but I don't know better way.
    eval "Faker::#{input}" # rubocop:disable Security/Eval,Style/EvalWithLocation
  end

  def cz_fake(input)
    # Not nice, but I don't know better way.
    eval "CzFaker::#{input}" # rubocop:disable Security/Eval,Style/EvalWithLocation
  end
end
