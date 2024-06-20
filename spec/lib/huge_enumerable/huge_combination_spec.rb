require 'spec_helper'

describe HugeCombination do

  let(:enumerable) { ('a'..'z').to_a }
  let(:combination_size) { 3 }

  subject(:combination) do
    HugeCombination.send(:public, :collection_size)
    HugeCombination.send(:public, :fetch)
    HugeCombination.new(enumerable, combination_size)
  end

  def enum_combo(x)
    @cache ||= {}
    @cache[x.to_i] ||= enumerable.combination(x).to_a
  end

  context "#collection_size" do

    it "is equal to array#combination.to_a.size" do
      expect(combination.collection_size).to eql(enum_combo(combination_size).size)
    end

  end

  context "#fetch" do

    it "returns values in the same order as array#combination.to_a[]" do
      enum_combo_fetches = []
      combination_fetches = []
      enum_combo(combination_size).size.times { |i| enum_combo_fetches << enum_combo(combination_size)[i] }
      combination.collection_size.times { |i| combination_fetches << combination.fetch(i) }
      expect(combination_fetches).to eql(enum_combo_fetches)
    end

  end

end