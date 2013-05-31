require 'spec_helper'

describe HugeCombination do

  let(:enumerable) { ('a'..'z').to_a }

  subject(:combination) do
    HugeCombination.new(enumerable, 2)
  end

  def enum_combo(x)
    @cache ||= {}
    @cache[x.to_i] ||= enumerable.combination(x).to_a
  end

  context "#collection_size" do

    it "is equal to array#combination.to_a.size" do
      combination.collection_size.should eql(enum_combo(2).size)
    end

  end

  context "#fetch" do

    it "returns values in the same order as array#combination.to_a[]" do
      enum_combo_fetches = []
      combination_fetches = []
      enum_combo(2).size.times { |i| enum_combo_fetches << enum_combo(2)[i] }
      combination.collection_size.times { |i| combination_fetches << combination.fetch(i) }
      combination_fetches.should eql(enum_combo_fetches)
    end

  end

end