require 'spec_helper'

describe HugeEnumerable do

  let(:collection) { ('a'..'z').to_a }

  subject(:enumerable) do
    klass = Class.new(HugeEnumerable)
    enum_collection = collection.sort
    klass.define_method(:collection_size) { enum_collection.size }
    klass.define_method(:fetch) { |x| enum_collection[x] }
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
        enumerable.max_array_size.should be_kind_of(Numeric)
      end

      it "defaults rng to #rand" do
        enumerable.rng.should eq(enumerable.method(:rand))
      end

    end

  end

  context "#[]" do

    context "with a positive index" do
      it "returns the element from the beginning of the collection at the specified index" do
        enumerable[3].should eql(collection[3])
      end
    end

    context "with a negative index" do
      it "returns the element from the end of the collection at the specified index" do
        enumerable[-3].should eql(collection[-3])
      end
    end

    context "with an out of bounds index" do
      it "returns nil" do
        enumerable[enumerable.size + 1].should be_nil
      end
    end

    context "with a range" do
      it "returns an array of elements corresponding to indexes within the range" do
        size = collection.size + 1
        test_range = (-size..size).to_a
        ranges = test_range.product(test_range).map { |x| (x.first..x.last) }
        arrays = ranges.map { |range| [enumerable[range], collection[range]] }
        arrays.each { |x| x.first.should eq(x.last) }
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
        arrays.each { |x| x.first.should eq(x.last) }
      end
    end


    it "relays to #_fetch for index mapping" do
      enumerable.should_receive(:_fetch).at_least(:once)
      enumerable[0]
    end

  end

  context "#each" do

    it "yields #max_array_size items" do
      items = []
      total_items = collection.size / 5
      enumerable.max_array_size = total_items
      enumerable.each { |x| items << x }
      items.size.should eql(total_items)
    end

    it "yields only the remaining items if there are fewer than #max_array_size" do
      items = []
      enumerable.max_array_size = collection.size + 1
      enumerable.each { |x| items << x }
      items.size.should eql(collection.size)
    end

    it "relays to #_fetch for index mapping" do
      enumerable.should_receive(:_fetch).at_least(:once)
      enumerable.each {}
    end

  end

  context "#combination" do

    context "with no block" do

      it "returns a new HugeCombination" do
        enumerable.combination(2).should be_instance_of(HugeCombination)
      end

    end

    context "with a block" do

      # This should really be calls the block from the combination since there is testing duplication here.
      # However, knowing where the block is called from would need stack investigation or similar.
      it "calls the block for each combination element" do
        combo = enumerable.combination(2)
        enumerable.max_array_size = combo.size  # Hrm. Perhaps having to do this is a reason to have it call collection_each
        index = 0
        enumerable.combination(2) do |x|
          x.should eql(combo[index])
          index += 1
        end
        index.should eql(combo.size)
      end

      it "returns self" do
        enumerable.combination(2) {}.should equal(enumerable)
      end

    end

    it "uses self a dup of itself as the enumerable" do
      dupped_enumerable = enumerable.dup
      enumerable.stub(:dup).and_return(dupped_enumerable)
      HugeCombination.should_receive(:new).with(dupped_enumerable, 2, enumerable.max_array_size, nil)
      enumerable.combination(2)
    end

    it "uses the same max array size" do
      enumerable.combination(2).max_array_size.should eql(enumerable.max_array_size)
    end

    it "uses the same random number generator" do
      enumerable.rng = Proc.new { 1 }
      enumerable.combination(2).rng.should eq(enumerable.rng)
    end

    it "calls reset! on the dup" do
      HugeEnumerable.send(:public, :reset!)
      dupped_enumerable = enumerable.dup
      enumerable.stub(:dup).and_return(dupped_enumerable)
      dupped_enumerable.should_receive(:reset!).and_call_original
      enumerable.combination(2)
    end

  end


  context "#max_array_size" do

    context "not explicitly set" do

      it "defaults to DEFAULT_MAX_ARRAY_SIZE if smaller than #collection_size" do
        enumerable.stub(:collection_size).and_return(HugeEnumerable::DEFAULT_MAX_ARRAY_SIZE + 1)
        enumerable.max_array_size.should eql(HugeEnumerable::DEFAULT_MAX_ARRAY_SIZE)
      end

      it "defaults to #collection_size if smaller than DEFAULT_MAX_ARRAY_SIZE" do
        enumerable.stub(:collection_size).and_return(HugeEnumerable::DEFAULT_MAX_ARRAY_SIZE - 1)
        enumerable.max_array_size.should eql(HugeEnumerable::DEFAULT_MAX_ARRAY_SIZE - 1)
      end

    end

  end

  context "#next_array" do

    it "advances to the next array in the collection" do
      size = collection.size / 5
      enumerable.max_array_size = size
      enumerable.next_array.should eql(collection[size...size*2])
    end

    it "changes #size" do
      size = collection.size / 5
      enumerable.max_array_size = size
      enumerable.next_array
      enumerable.size.should eql(collection.size - size)
    end

  end

  context "#empty?" do

    it "returns true if the collection has been entirely emptied by #pop, #shift, or #next_array" do
      enumerable.max_array_size = collection.size
      enumerable.next_array
      enumerable.empty?.should be_true
    end

    it "returns false if the collection has been not entirely emptied by #pop, #shift, or #next_array" do
      enumerable.max_array_size = collection.size - 1
      enumerable.next_array
      enumerable.empty?.should be_false
    end

  end

  context "#permutation" do

    context "with no block" do

      it "returns a new HugePermutation" do
        enumerable.permutation(2).should be_instance_of(HugePermutation)
      end

    end

    context "with a block" do

      # This should really be calls the block from the combination since there is testing duplication here.
      # However, knowing where the block is called from would need stack investigation or similar.
      it "calls the block for each permutation element" do
        perm = enumerable.permutation(2)
        enumerable.max_array_size = perm.size  # Hrm. Perhaps having to do this is a reason to have it call collection_each
        index = 0
        enumerable.permutation(2) do |x|
          x.should eql(perm[index])
          index += 1
        end
        index.should eql(perm.size)
      end

      it "returns self" do
        enumerable.permutation(2) {}.should equal(enumerable)
      end

    end

    it "uses self a dup of itself as the enumerable" do
      dupped_enumerable = enumerable.dup
      enumerable.stub(:dup).and_return(dupped_enumerable)
      HugePermutation.should_receive(:new).with(dupped_enumerable, 2, enumerable.max_array_size, nil)
      enumerable.permutation(2)
    end

    it "uses the same max array size" do
      enumerable.permutation(2).max_array_size.should eql(enumerable.max_array_size)
    end

    it "uses the same random number generator" do
      enumerable.rng = Proc.new { 1 }
      enumerable.permutation(2).rng.should eq(enumerable.rng)
    end

    it "calls reset! on the dup" do
      HugeEnumerable.send(:public, :reset!)
      dupped_enumerable = enumerable.dup
      enumerable.stub(:dup).and_return(dupped_enumerable)
      dupped_enumerable.should_receive(:reset!).and_call_original
      enumerable.permutation(2)
    end

  end


  context "#pop" do

    context "on a non empty collection" do
      context "with no parameter" do
        it "returns the next element from the end of the collection" do
          enumerable.pop.should eql(collection.pop)
        end
      end

      context "with a parameter" do
        it "returns an array of the next N elements from the end of the collection" do
          enumerable.pop(3).should eql(collection.pop(3))
        end
      end

      it "removes the elements from the end of the collection" do
        enumerable.pop
        enumerable.pop(3)
        enumerable.to_a.should eql(collection[0..-5])
      end

      it "changes #size" do
        enumerable.pop
        enumerable.pop(3)
        enumerable.size.should eql(collection.size - 4)
      end

      it "does not harm the original collection" do
        original = collection.dup
        enumerable.pop
        enumerable.pop(3)
        collection.should eql(original)
      end

    end

    it "depends on #(private)element_or_array" do
      enumerable.should_receive(:element_or_array).twice.and_call_original
      enumerable.pop
      enumerable.pop(3)
    end

  end

  context "#product" do

    context "with no block" do

      it "returns a new HugeProduct" do
        enumerable.product([]).should be_instance_of(HugeProduct)
      end

    end

    context "with a block" do

      # This should really be calls the block from the combination since there is testing duplication here.
      # However, knowing where the block is called from would need stack investigation or similar.
      it "calls the block for each product element" do
        other_enumerable = [1, 2, 3]
        prod = enumerable.product(other_enumerable)
        enumerable.max_array_size = prod.size  # Hrm. Perhaps having to do this is a reason to have it call collection_each
        index = 0
        enumerable.product(other_enumerable) do |x|
          x.should eql(prod[index])
          index += 1
        end
        index.should eql(prod.size)
      end

      it "returns self" do
        enumerable.product([]) {}.should equal(enumerable)
      end

    end

    it "uses self a dup of itself as the enumerable" do
      dupped_enumerable = enumerable.dup
      enumerable.stub(:dup).and_return(dupped_enumerable)
      other_enumerable = []
      HugeProduct.should_receive(:new).with(dupped_enumerable, other_enumerable, enumerable.max_array_size, nil)
      enumerable.product(other_enumerable)
    end

    it "calls dup on the other enumerable if it is a HugeEnumerable" do
      other_enumerable = HugeCollection.new([])
      other_enumerable.should_receive(:dup).and_call_original
      enumerable.product(other_enumerable)
    end

    it "calls reset on the other enumerable if it is a HugeEnumerable" do
      HugeEnumerable.send(:public, :reset!)
      other_enumerable = HugeCollection.new([])
      dupped_enumerable = other_enumerable.dup
      other_enumerable.stub(:dup).and_return(dupped_enumerable)
      dupped_enumerable.should_receive(:reset!).and_call_original
      enumerable.product(other_enumerable)
    end

    it "does not call dup on the other enumerable if it is a HugeEnumerable" do
      other_enumerable = []
      other_enumerable.should_not_receive(:dup)
      enumerable.product(other_enumerable)
    end

    it "uses the same max array size" do
      enumerable.product([]).max_array_size.should eql(enumerable.max_array_size)
    end

    it "uses the same random number generator" do
      enumerable.rng = Proc.new { 1 }
      enumerable.product([]).rng.should eq(enumerable.rng)
    end

    it "calls reset! on the dup" do
      HugeEnumerable.send(:public, :reset!)
      dupped_enumerable = enumerable.dup
      enumerable.stub(:dup).and_return(dupped_enumerable)
      dupped_enumerable.should_receive(:reset!).and_call_original
      enumerable.product([])
    end

  end

  context "#sample" do

    context "on an non empty collection" do
      context "with no arguments" do
        it "returns a single element from the collection" do
          collection.include?(enumerable.sample).should be_true
        end
      end

      context "with size argument" do
        it "returns N elements from the collection" do
          samples = enumerable.sample(3)
          samples.should have(3).items
          samples.all? { |item| collection.include?(item) }.should be_true
        end
      end

      it "returns elements from the collection in a pseudo random pattern" do
        enumerable.sample(enumerable.size).should_not eq(collection)
      end

      it "visits each element exactly once before repeating" do
        samples = []
        enumerable.size.times { samples << enumerable.sample }
        samples.uniq.should have(collection.size).items
      end

      it "does not reorder the original collection" do
        original = collection.dup
        enumerable.sample
        enumerable.sample(3)
        collection.should eql(original)
      end

    end

    it "depends on #(private)element_or_array" do
      enumerable.should_receive(:element_or_array).twice.and_call_original
      enumerable.sample
      enumerable.sample(3)
    end

  end

  context "#shift" do

    context "on a non empty collection" do
      context "with no parameter" do
        it "returns the next element from the beginning of the collection" do
          enumerable.shift.should eql(collection.shift)
        end
      end

      context "with a parameter" do
        it "returns an array of the next N elements from the beginning of the collection" do
          enumerable.shift(3).should eql(collection.shift(3))
        end
      end

      it "removes the elements from the beginning of the collection" do
        enumerable.shift
        enumerable.shift(3)
        enumerable.to_a.should eql(collection[4..-1])
      end

      it "changes #size" do
        enumerable.shift
        enumerable.shift(3)
        enumerable.size.should eql(collection.size - 4)
      end

      it "does not harm the original collection" do
        original = collection.dup
        enumerable.shift
        enumerable.shift(3)
        collection.should eql(original)
      end

    end

    it "depends on #(private)element_or_array" do
      enumerable.should_receive(:element_or_array).twice.and_call_original
      enumerable.shift
      enumerable.shift(3)
    end

  end

  context "#shuffle" do

    it "returns a new HugeEnumerable" do
      enumerable.shuffle.should_not equal(enumerable)
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
      original.should_not eq(shuffle1)
      original.should_not eq(shuffle2)
      shuffle1.should_not eq(shuffle2)
    end

    it "contains all of the original elements" do
      enumerable.shuffle!.to_a.sort.should eq(collection)
    end

    it "does noy alter the original collection" do
      original = collection.dup
      enumerable.max_array_size = enumerable.size
      enumerable.shuffle!
      enumerable.to_a.should_not eq(original)
      original.should eq(collection)
    end

  end

  context "#size" do

    it "returns the current size of the collection" do
      enumerable.size.should eql(collection.size)
    end

  end

  context "#(private)next_prime" do

    it "should return the next prime following any integer" do
      primes = Prime.first(100)
      x = 0
      until primes.empty?
        enumerable.next_prime(x).should eq(primes.first)
        x += 1
        primes.shift if x.prime?
      end
    end

  end

  context "#(private)_fetch" do

    context "with an index outside the range of (sequence_start..sequence_end)" do
      it "should never relay to fetch" do
        enumerable.should_not_receive(:fetch)
        enumerable._fetch(-1 * enumerable.size - 1)
        enumerable._fetch(enumerable.size)
      end
    end

    context "with an index inside the range of (sequence_start..sequence_end)" do
      it "should relay to fetch" do
        enumerable.should_receive(:fetch).twice
        enumerable._fetch(0)
        enumerable._fetch(enumerable.size - 1)
      end

      it "should map the relative index to an absolute index before calling fetch" do
        enumerable.shift(3)
        enumerable.stub(:shuffle_index) { |index| index + 2 }
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
          enumerable.element_or_array { block.call }.should eql(1)
        end
      end

      context "with a nil parameter" do
        it "returns a single element" do
          enumerable.element_or_array(nil, &block).should eql(1)
        end
      end

      context "with a non nil parameter" do
        it "returns an array of N elements" do
          enumerable.element_or_array(3, &block).should eql([1, 1, 1])
        end

        it "will not return more items than remain in the collection" do
          size = enumerable.size
          enumerable.element_or_array(size + 1, &block).should have(size).items
        end
      end
    end

    context "on an empty collection" do
      context "with no parameter" do
        it "returns nil" do
          emptied_enumerable.element_or_array(&:block).should be_nil
        end
      end

      context "with a parameter" do
        it "returns an empty array" do
          emptied_enumerable.element_or_array(3, &block).should eql([])
        end
      end
    end

    it "raises an exception if the parameter is negative" do
      expect { enumerable.element_or_array(-1, &block) }.to raise_error(ArgumentError, 'negative array size')
    end

  end

  context "#(private)full_cycle_increment" do

    it "must never return a value equal to the domain size" do
      (0...100).to_a.all? { |x| enumerable.full_cycle_increment(x) != x }.should be_true
    end

  end

end