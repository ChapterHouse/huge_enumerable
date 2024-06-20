require 'spec_helper'

describe HugePermutation do

  let(:enumerable) { ('a'..'z').to_a }
  let(:permutation_size) { 3 }

  subject(:permutation) do
    HugePermutation.send(:public, :collection_size)
    HugePermutation.send(:public, :fetch)
    HugePermutation.new(enumerable, permutation_size)
  end

  def enum_perm(x)
    @cache ||= {}
    @cache[x.to_i] ||= enumerable.permutation(x).to_a
  end

  context "#collection_size" do

    it "is equal to array#permutation.to_a.size" do
      expect(permutation.collection_size).to eql(enum_perm(permutation_size).size)
    end

  end

  context "#fetch" do

    it "returns values in the same order as array#permutation.to_a[]" do
      enum_perm_fetches = []
      permutation_fetches = []
      enum_perm(permutation_size).size.times { |i| enum_perm_fetches << enum_perm(permutation_size)[i] }
      permutation.collection_size.times { |i| permutation_fetches << permutation.fetch(i) }
      expect(permutation_fetches).to eql(enum_perm_fetches)
    end

  end

end