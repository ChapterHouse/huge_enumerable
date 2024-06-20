require 'spec_helper'

describe HugeCollection do

  let(:enumerable) { ('a'..'z').to_a }

  subject(:collection) do
    HugeCollection.send(:public, :collection_size)
    HugeCollection.send(:public, :fetch)
    HugeCollection.new(enumerable)
  end

  context "#collection_size" do

    it "is equal to the original enumerable size" do
      expect(collection.collection_size).to eql(enumerable.size)
    end

  end

  context "#fetch" do

    it "returns values in the same order as enumerable[]" do
      enumerable_fetches = []
      collection_fetches = []
      enumerable.size.times { |i| enumerable_fetches << enumerable[i] }
      collection.collection_size.times { |i| collection_fetches << collection.fetch(i) }
      expect(collection_fetches).to eql(enumerable_fetches)
    end

  end

end