require 'spec_helper'

describe HugeEnumerable do

  let(:collection) { ('a'..'z').to_a }

  subject(:enumerable) do
    klass = Class.new(HugeEnumerable)
    enum_collection = collection.sort
    klass.send(:define_method, :collection_size) { enum_collection.size }
    klass.send(:define_method, :fetch) { |x| enum_collection[x] }
    klass.send(:public, :next_prime)
    klass.send(:public, :_fetch)
    klass.send(:public, :element_or_array)
    klass.send(:public, :full_cycle_increment)
    klass.new
  end

  subject(:emptied_enumerable) do
    enumerable.tap do |enum|
      enum.max_array_size = enum.size
      enum.next_array
    end
  end

  context ".new" do

    context "with no arguments" do

      it "defaults max_array_size to a Numeric" do
        expect(enumerable.max_array_size).to be_a_kind_of(Numeric)
      end

      it "defaults rng to #rand" do
        expect(enumerable.rng).to eq(enumerable.method(:rand))
      end

    end

  end

  context "#[]" do

    context "with a positive index" do
      it "returns the element from the beginning of the collection at the specified index" do
        expect(enumerable[3]).to eql(collection[3])
      end
    end

    context "with a negative index" do
      it "returns the element from the end of the collection at the specified index" do
        expect(enumerable[-3]).to eql(collection[-3])
      end
    end

    context "with an out of bounds index" do
      it "returns nil" do
        expect(enumerable[enumerable.size + 1]).to be_nil
      end
    end

    context "with a range" do
      it "returns an array of elements corresponding to indexes within the range" do
        size = collection.size + 1
        test_range = (-size..size).to_a
        ranges = test_range.product(test_range).map { |x| (x.first..x.last) }
        arrays = ranges.map { |range| [enumerable[range], collection[range]] }
        arrays.each { |x| expect(x.first).to eq(x.last) }
      end
    end

    context "with a length" do
      it "returns an array of elements corresponding to starting with index and containing a maximum of length items" do
        size = collection.size + 1
        test_range = (-size..size).to_a
        index_lengths = test_range.product(test_range).map { |x| [x.first, x.last] }
        arrays = index_lengths.map do |idx_len|
          index = idx_len.first
          length = idx_len.last
          [enumerable[index, length], collection[index, length]]
        end
        arrays.each { |x| expect(x.first).to eq(x.last) }
      end
    end

    it "relays to #_fetch for index mapping" do
      expect(enumerable).to receive(:_fetch).at_least(:once)
      enumerable[0]
    end

  end

  context "#each" do

    it "yields #max_array_size items" do
      items = []
      total_items = collection.size / 5
      enumerable.max_array_size = total_items
      enumerable.each { |x| items << x }
      expect(items.size).to eql(total_items)
    end

    it "yields only the remaining items if there are fewer than #max_array_size" do
      items = []
      enumerable.max_array_size = collection.size + 1
      enumerable.each { |x| items << x }
      expect(items.size).to eql(collection.size)
    end

    it "relays to #_fetch for index mapping" do
      expect(enumerable).to receive(:_fetch).at_least(:once)
      enumerable.each {}
    end

  end

  context "#combination" do

    context "with no block" do

      it "returns a new HugeCombination" do
        expect(enumerable.combination(2)).to be_an_instance_of(HugeCombination)
      end

    end

    context "with a block" do

      it "calls the block for each combination element" do
        combo = enumerable.combination(2)
        enumerable.max_array_size = combo.size  # Hrm. Perhaps having to do this is a reason to have it call collection_each
        index = 0
        enumerable.combination(2) do |x|
          expect(x).to eql(combo[index])
          index += 1
        end
        expect(index).to eq(combo.size)
      end

      it "returns self" do
        expect(enumerable.combination(2) {}).to equal(enumerable)
      end

    end

    it "uses clone of itself as the enumerable" do
      cloned_enumerable = enumerable.clone
      expect(enumerable).to receive(:clone).and_return(cloned_enumerable)
      expect(HugeCombination).to receive(:new).with(cloned_enumerable, 2, enumerable.max_array_size, nil)
      enumerable.combination(2)
    end

    it "uses the same max array size" do
      expect(enumerable.combination(2).max_array_size).to eq(enumerable.max_array_size)
    end

    it "uses the same random number generator" do
      # As a method
      rng = enumerable.rng
      combo_rng = enumerable.combination(2).rng
      expect(combo_rng.owner).to be(rng.owner)
      expect(combo_rng.original_name).to be(rng.original_name)
      expect(combo_rng.source_location).to be(rng.source_location)
      
      # As a proc
      enumerable.rng = Proc.new { 1 }
      expect(enumerable.combination(2).rng).to be(enumerable.rng)
    end

    it "calls reset! on the clone" do
      HugeEnumerable.send(:public, :reset!)
      cloned_enumerable = enumerable.clone
      expect(enumerable).to receive(:clone).and_return(cloned_enumerable)
      expect(cloned_enumerable).to receive(:reset!).and_call_original
      enumerable.combination(2)
    end

  end


  context "#max_array_size" do

    context "not explicitly set" do

      it "defaults to DEFAULT_MAX_ARRAY_SIZE if smaller than #collection_size" do
        collection_size = HugeEnumerable::DEFAULT_MAX_ARRAY_SIZE + 1
        expect(enumerable).to receive(:collection_size).and_return(collection_size)
        expect(enumerable.max_array_size).to eq(HugeEnumerable::DEFAULT_MAX_ARRAY_SIZE)
      end

      it "defaults to #collection_size if smaller than DEFAULT_MAX_ARRAY_SIZE" do
        collection_size = HugeEnumerable::DEFAULT_MAX_ARRAY_SIZE - 1
        expect(enumerable).to receive(:collection_size).and_return(collection_size)
        expect(enumerable.max_array_size).to eq(collection_size)
      end

    end

  end

  context "#next_array" do
    
    let(:size) { collection.size / 5 }

    before :each do
      enumerable.max_array_size = size
    end

    it "advances to the next array in the collection" do
      expect(enumerable.next_array).to eq(collection[size...size*2])
    end

    it "changes #size" do
      enumerable.next_array
      expect(enumerable.size).to eq(collection.size - size)
    end

  end

  context "#empty?" do

    it "returns true if the collection has been entirely emptied by #pop, #shift, or #next_array" do
      enumerable.max_array_size = collection.size
      enumerable.next_array
      expect(enumerable.empty?).to be_truthy
    end

    it "returns false if the collection has been not entirely emptied by #pop, #shift, or #next_array" do
      enumerable.max_array_size = collection.size - 1
      enumerable.next_array
      expect(enumerable.empty?).to be_falsey
    end

  end

  context "#permutation" do

    context "with no block" do

      it "returns a new HugePermutation" do
        expect(enumerable.permutation(2)).to be_instance_of(HugePermutation)
      end

    end

    context "with a block" do

      it "calls the block for each permutation element" do
        perm = enumerable.permutation(2)
        enumerable.max_array_size = perm.size  # Hrm. Perhaps having to do this is a reason to have it call collection_each
        index = 0
        enumerable.permutation(2) do |x|
          expect(x).to eql(perm[index])
          index += 1
        end
        expect(index).to eq(perm.size)
      end

      it "returns self" do
        expect(enumerable.permutation(2) {}).to be(enumerable)
      end

    end

    it "uses self a clone of itself as the enumerable" do
      cloned_enumerable = enumerable.clone
      expect(enumerable).to receive(:clone).and_return(cloned_enumerable)
      expect(HugePermutation).to receive(:new).with(cloned_enumerable, 2, enumerable.max_array_size, nil)
      enumerable.permutation(2)
    end

    it "uses the same max array size" do
      expect(enumerable.permutation(2).max_array_size).to eq(enumerable.max_array_size)
    end

    it "uses the same random number generator" do
      # As a method
      rng = enumerable.rng
      combo_rng = enumerable.permutation(2).rng
      expect(combo_rng.owner).to be(rng.owner)
      expect(combo_rng.original_name).to be(rng.original_name)
      expect(combo_rng.source_location).to be(rng.source_location)

      # As a proc
      enumerable.rng = Proc.new { 1 }
      expect(enumerable.permutation(2).rng).to be(enumerable.rng)
    end

    it "calls reset! on the dup" do
      HugeEnumerable.send(:public, :reset!)
      cloned_enumerable = enumerable.dup
      expect(enumerable).to receive(:clone).and_return(cloned_enumerable)
      expect(cloned_enumerable).to receive(:reset!).and_call_original
      enumerable.permutation(2)
    end

  end


  context "#pop" do

    context "on a non empty collection" do
      context "with no parameter" do
        it "returns the next element from the end of the collection" do
          expect(enumerable.pop).to be(collection.pop)
        end
      end

      context "with a parameter" do
        it "returns an array of the next N elements from the end of the collection" do
          expect(enumerable.pop(3)).to eql(collection.pop(3))
        end
      end

      it "removes the elements from the end of the collection" do
        enumerable.pop
        enumerable.pop(3)
        expect(enumerable.to_a).to eql(collection[0..-5])
      end

      it "changes #size" do
        enumerable.pop
        enumerable.pop(3)
        expect(enumerable.size).to eql(collection.size - 4)
      end

      it "does not harm the original collection" do
        original = collection.dup
        enumerable.pop
        enumerable.pop(3)
        expect(collection).to eql(original)
      end

    end

    it "depends on #(private)element_or_array" do
      expect(enumerable).to receive(:element_or_array).twice.and_call_original
      enumerable.pop
      enumerable.pop(3)
    end

  end

  context "#product" do

    context "with no block" do

      it "returns a new HugeProduct" do
        expect(enumerable.product([])).to be_instance_of(HugeProduct)
      end

    end

    context "with a block" do

      it "calls the block for each product element" do
        other_enumerable = [1, 2, 3]
        prod = enumerable.product(other_enumerable)
        enumerable.max_array_size = prod.size  # Hrm. Perhaps having to do this is a reason to have it call collection_each
        index = 0
        enumerable.product(other_enumerable) do |x|
          expect(x).to eql(prod[index])
          index += 1
        end
        expect(index).to eq(prod.size)
      end

      it "returns self" do
        expect(enumerable.product([]) {}).to be(enumerable)
      end

    end

    it "uses self a dup of itself as the enumerable" do
      cloned_enumerable = enumerable.clone
      expect(enumerable).to receive(:clone).and_return(cloned_enumerable)
      other_enumerable = []
      expect(HugeProduct).to receive(:new).with(cloned_enumerable, other_enumerable, enumerable.max_array_size, nil)
      enumerable.product(other_enumerable)
    end

    it "calls clone on the other enumerable if it is a HugeEnumerable" do
      other_enumerable = HugeCollection.new([])
      expect(other_enumerable).to receive(:clone).and_call_original
      enumerable.product(other_enumerable)
    end

    it "calls reset on the other enumerable if it is a HugeEnumerable" do
      HugeEnumerable.send(:public, :reset!)
      other_enumerable = HugeCollection.new([])
      cloned_enumerable = other_enumerable.clone
      expect(enumerable).to receive(:clone).and_return(cloned_enumerable)
      expect(cloned_enumerable).to receive(:reset!).and_call_original
      enumerable.product(other_enumerable)
    end

    it "does not call clone on the other enumerable if it is a HugeEnumerable" do
      other_enumerable = []
      expect(other_enumerable).to_not receive(:clone)
      enumerable.product(other_enumerable)
    end

    it "uses the same max array size" do
      expect(enumerable.product([]).max_array_size).to eq(enumerable.max_array_size)
    end

    it "uses the same random number generator" do
      # As a method
      rng = enumerable.rng
      product_rng = enumerable.product([]).rng
      expect(product_rng.owner).to be(rng.owner)
      expect(product_rng.original_name).to be(rng.original_name)
      expect(product_rng.source_location).to be(rng.source_location)

      # As a proc
      enumerable.rng = Proc.new { 1 }
      expect(enumerable.product([]).rng).to be(enumerable.rng)
    end

    it "calls reset! on the dup" do
      HugeEnumerable.send(:public, :reset!)
      cloned_enumerable = enumerable.clone
      expect(enumerable).to receive(:clone).and_return(cloned_enumerable)
      expect(cloned_enumerable).to receive(:reset!).and_call_original
      enumerable.product([])
    end

  end

  context "#sample" do

    context "on an non empty collection" do
      context "with no arguments" do
        it "returns a single element from the collection" do
          expect(collection.include?(enumerable.sample)).to be_truthy
        end
      end

      context "with size argument" do
        it "returns N elements from the collection" do
          samples = enumerable.sample(3)
          expect(samples.size).to eq(3)
          expect(samples.all? { |item| collection.include?(item) }).to be_truthy
        end
      end

      it "returns elements from the collection in a pseudo random pattern" do
        expect(enumerable.sample(enumerable.size)).to_not eq(collection)
      end

      it "visits each element exactly once before repeating" do
        samples = []
        enumerable.size.times { samples << enumerable.sample }
        expect(samples.uniq.size).to eq(collection.size)
      end

      it "does not reorder the original collection" do
        original = collection.dup
        enumerable.sample
        enumerable.sample(3)
        expect(collection).to eql(original)
      end

    end

    it "depends on #(private)element_or_array" do
      expect(enumerable).to receive(:element_or_array).twice.and_call_original
      enumerable.sample
      enumerable.sample(3)
    end

  end

  context "#shift" do

    context "on a non empty collection" do
      context "with no parameter" do
        it "returns the next element from the beginning of the collection" do
          expect(enumerable.shift).to eql(collection.shift)
        end
      end

      context "with a parameter" do
        it "returns an array of the next N elements from the beginning of the collection" do
          expect(enumerable.shift(3)).to eql(collection.shift(3))
        end
      end

      it "removes the elements from the beginning of the collection" do
        enumerable.shift
        enumerable.shift(3)
        expect(enumerable.to_a).to eql(collection[4..-1])
      end

      it "changes #size" do
        enumerable.shift
        enumerable.shift(3)
        expect(enumerable.size).to eql(collection.size - 4)
      end

      it "does not harm the original collection" do
        original = collection.dup
        enumerable.shift
        enumerable.shift(3)
        expect(collection).to eql(original)
      end

    end

    it "depends on #(private)element_or_array" do
      expect(enumerable).to receive(:element_or_array).twice.and_call_original
      enumerable.shift
      enumerable.shift(3)
    end

  end

  context "#shuffle" do

    it "returns a new HugeEnumerable" do
      expect(enumerable.shuffle).to_not equal(enumerable)
    end

  end

  context "#shuffle!" do

    it "randomly alters the order of the sequence" do
      fake_random = Proc.new { |x| 2 % x }
      enumerable.max_array_size = enumerable.size
      original = enumerable.to_a
      enumerable.shuffle!(fake_random)
      shuffle1 = enumerable.to_a
      fake_random = Proc.new { |x| 3 % x }
      enumerable.shuffle!(fake_random)
      shuffle2 = enumerable.to_a
      expect(original).to_not eq(shuffle1)
      expect(original).to_not eq(shuffle2)
      expect(shuffle1).to_not eq(shuffle2)
    end

    it "contains all of the original elements" do
      expect(enumerable.shuffle!.to_a.sort).to eq(collection)
    end

    it "does noy alter the original collection" do
      original = collection.dup
      enumerable.max_array_size = enumerable.size
      enumerable.shuffle!
      expect(enumerable.to_a).to_not eq(original)
      expect(original).to eq(collection)
    end

  end

  context "#size" do

    it "returns the current size of the collection" do
      expect(enumerable.size).to eql(collection.size)
    end

  end

  context "#(private)next_prime" do

    it "should return the next prime following any integer" do
      primes = Prime.first(100)
      x = 0
      until primes.empty?
        expect(enumerable.next_prime(x)).to eq(primes.first)
        x += 1
        primes.shift if x.prime?
      end
    end

  end

  context "#(private)_fetch" do

    context "with an index outside the range of (sequence_start..sequence_end)" do
      it "should never relay to fetch" do
        expect(enumerable).to_not receive(:fetch)
        enumerable._fetch(-1 * enumerable.size - 1)
        enumerable._fetch(enumerable.size)
      end
    end

    context "with an index inside the range of (sequence_start..sequence_end)" do
      it "should relay to fetch" do
        expect(enumerable).to receive(:fetch).twice
        enumerable._fetch(0)
        enumerable._fetch(enumerable.size - 1)
      end

      it "should map the relative index to an absolute index before calling fetch" do
        enumerable.shift(3)
        expect(enumerable).to receive(:shuffle_index) { |index| index + 2 }
        enumerable.should_receive(:fetch).with(5)
        enumerable._fetch(0)
      end

    end

  end

  context "#(private)element_or_array" do

    let(:block) { Proc.new { 1 } }

    context "on a non empty collection" do
      context "with no parameter" do
        it "returns a single element" do
          expect(enumerable.element_or_array(&block)).to eql(1)
        end
      end

      context "with a nil parameter" do
        it "returns a single element" do
          expect(enumerable.element_or_array(nil, &block)).to eql(1)
        end
      end

      context "with a non nil parameter" do
        it "returns an array of N elements" do
          expect(enumerable.element_or_array(3, &block)).to eql([1, 1, 1])
        end

        it "will not return more items than remain in the collection" do
          size = enumerable.size
          expect(enumerable.element_or_array(size + 1, &block).size).to eq(size)
        end
      end
    end

    context "on an empty collection" do
      context "with no parameter" do
        it "returns nil" do
          expect(emptied_enumerable.element_or_array(&:block)).to be_nil
        end
      end

      context "with a parameter" do
        it "returns an empty array" do
          expect(emptied_enumerable.element_or_array(3, &block)).to eql([])
        end
      end
    end

    it "raises an exception if the parameter is negative" do
      expect { enumerable.element_or_array(-1, &block) }.to raise_error(ArgumentError, 'negative array size')
    end

  end

  context "#(private)full_cycle_increment" do

    it "must never return a value equal to the domain size" do
      expect((0...100).to_a.all? { |x| enumerable.full_cycle_increment(x) != x }).to be_truthy
    end

  end

end