require 'spec_helper'

describe HugeEnumerable do

  let(:array) { ('a'..'z').to_a }

  subject(:enumerable) do
    HugeEnumerable.new.tap do |enum|
      enum.stub(:collection_size).and_return(array.size)
      enum.stub(:fetch) { |x| array[x] }
    end
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
        enumerable[3].should eql(array[3])
      end
    end

    context "with a negative index" do
      it "returns the element from the end of the collection at the specified index" do
        enumerable[-3].should eql(array[-3])
      end
    end

    context "with an out of bounds index" do
      it "returns nil" do
        enumerable[enumerable.size + 1].should be_nil
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
      total_items = array.size / 5
      enumerable.max_array_size = total_items
      enumerable.each { |x| items << x }
      items.size.should eql(total_items)
    end

    it "yields only the remaining items if there are fewer than #max_array_size" do
      items = []
      enumerable.max_array_size = array.size + 1
      enumerable.each { |x| items << x }
      items.size.should eql(array.size)
    end

    it "relays to #_fetch for index mapping" do
      enumerable.should_receive(:_fetch).at_least(:once)
      enumerable.each {}
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
      size = array.size / 5
      enumerable.max_array_size = size
      enumerable.next_array.should eql(array[size...size*2])
    end

    it "changes #size" do
      size = array.size / 5
      enumerable.max_array_size = size
      enumerable.next_array
      enumerable.size.should eql(array.size - size)
    end

  end

  context "#empty?" do

    it "returns true if the collection has been entirely emptied by #pop, #shift, or #next_array" do
      enumerable.max_array_size = array.size
      enumerable.next_array
      enumerable.empty?.should be_true
    end

    it "returns false if the collection has been not entirely emptied by #pop, #shift, or #next_array" do
      enumerable.max_array_size = array.size - 1
      enumerable.next_array
      enumerable.empty?.should be_false
    end

  end

  context "#pop" do

    context "on a non empty collection" do
      context "with no parameter" do
        it "returns the next element from the end of the collection" do
          enumerable.pop.should eql(array.pop)
        end
      end

      context "with a parameter" do
        it "returns an array of the next N elements from the end of the collection" do
          enumerable.pop(3).should eql(array.pop(3))
        end

        it "will not return more items than remain in the collection" do
          size = enumerable.size
          enumerable.pop(size + 1).should have(size).items
        end
      end

      it "removes the elements from the end of the collection" do
        enumerable.pop
        enumerable.pop(3)
        enumerable.to_a.should eql(array[0..-5])
      end

      it "changes #size" do
        enumerable.pop
        enumerable.pop(3)
        enumerable.size.should eql(array.size - 4)
      end

      it "does not harm the original collection" do
        original = array.dup
        enumerable.pop
        enumerable.pop(3)
        array.should eql(original)
      end

    end

    context "on an empty collection" do
      context "with no parameter" do
        it "returns nil" do
          emptied_enumerable.pop.should be_nil
        end
      end

      context "with a parameter" do
        it "returns an empty array" do
          emptied_enumerable.pop(3).should eql([])
        end
      end
    end

    it "raises an exception if the parameter is negative" do
      expect { enumerable.pop(-1) }.to raise_error(ArgumentError, 'negative array size')
    end

  end

  context "#sample" do
    it("is implemented") { pending "tests to be written" }
  end

  context "#shift" do

    context "on a non empty collection" do
      context "with no parameter" do
        it "returns the next element from the beginning of the collection" do
          enumerable.shift.should eql(array.shift)
        end
      end

      context "with a parameter" do
        it "returns an array of the next N elements from the beginning of the collection" do
          enumerable.shift(3).should eql(array.shift(3))
        end

        it "will not return more items than remain in the collection" do
          size = enumerable.size
          enumerable.shift(size + 1).should have(size).items
        end
      end

      it "removes the elements from the beginning of the collection" do
        enumerable.shift
        enumerable.shift(3)
        enumerable.to_a.should eql(array[4..-1])
      end

      it "changes #size" do
        enumerable.shift
        enumerable.shift(3)
        enumerable.size.should eql(array.size - 4)
      end

      it "does not harm the original collection" do
        original = array.dup
        enumerable.shift
        enumerable.shift(3)
        array.should eql(original)
      end

    end

    context "on an empty collection" do
      context "with no parameter" do
        it "returns nil" do
          emptied_enumerable.shift.should be_nil
        end
      end

      context "with a parameter" do
        it "returns an empty array" do
          emptied_enumerable.shift(3).should eql([])
        end
      end
    end

    it "raises an exception if the parameter is negative" do
      expect { enumerable.shift(-1) }.to raise_error(ArgumentError, 'negative array size')
    end

  end

  context "#shuffle" do
    it("is implemented") { pending "tests to be written" }
  end

  context "#shuffle!" do
    it("is implemented") { pending "tests to be written" }
  end

  context "#size" do

    it "returns the current size of the collection" do
      enumerable.size.should eql(array.size)
    end

  end

end
