require 'spec_helper'

describe HugeProduct do

  let(:enumerable_a) { ('a'..'z').to_a }
  let(:enumerable_b) { ('A'..'Z').to_a }
  let(:enum_prod) { enumerable_a.product(enumerable_b) }

  subject(:product) do
    HugeProduct.send(:public, :collection_size)
    HugeProduct.send(:public, :fetch)
    HugeProduct.new(enumerable_a, enumerable_b)
  end

  context "#collection_size" do

    it "is equal to array#product(other_ary).size" do
      expect(product.collection_size).to eql(enum_prod.size)
    end

  end

  context "#fetch" do

    it "returns values in the same order as array#product(other_ary)[]" do
      enum_prod_fetches = []
      product_fetches = []
      enum_prod.size.times { |i| enum_prod_fetches << enum_prod[i] }
      product.collection_size.times { |i| product_fetches << product.fetch(i) }
      expect(product_fetches).to eql(enum_prod_fetches)
    end

  end

end