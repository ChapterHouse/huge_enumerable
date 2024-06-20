require "huge_enumerable/version"

require 'backports' if RUBY_VERSION < '1.9'
require 'prime'
require 'prime_miller_rabin'

Prime::MillerRabin.speed_intercept

# HugeEnumerable is a base class that allows for enumerations over very large (potentially infinite)
# data sets without requiring them to be in memory.
# In addition to enumerable, abilities it also allows for shuffling, sampling, shifting, and popping as if it were
# an array. These actions also do not require for the entire data set to be in memory. Nor do they alter the original
# data set in any fashion.
#
# To use HugeEnumerable, inherit it via a subclass and provide the methods collection_size and fetch.
# collection_size should return the size of the full data set.
# fetch should return the value at the given index.
# It is guaranteed that fetch will always be called with values in the range of (0...collection_size)
# It will never be called with a negative index or with an index >= collection_size
class HugeEnumerable

  include Enumerable

  # Currently 100,000 elements
  DEFAULT_MAX_ARRAY_SIZE=100000

  # The maximum number of elements to be returned when to_a is called.
  # If this is not set it will default to the collection_size or DEFAULT_MAX_ARRAY_SIZE depending on which is smaller.
  attr_accessor :max_array_size

  # The random number generator to use for shuffles and samples. Defaults to self#rand.
  attr_accessor :rng

  # Create a new HugeEnumerable
  #
  # ==== Options
  #
  # * +:max_array_size+ - The default size of arrays when #to_a is called.
  # * +:rng+ - The random number generator to use.
  def initialize(max_array_size = nil, rng = nil)
    @max_array_size = max_array_size ? max_array_size.to_i : nil
    @rng = rng || self.method(:rand)
    @collection_increment = 1
    @start_of_sequence = 0
    @shuffle_head = 0
  end

  # Element Reference — Returns the element at index, or returns a subarray starting at the start index and continuing for length elements, or returns a subarray specified by range of indices.
  # Negative indices count backward from the end of the collection (-1 is the last element).
  # For start and range cases the starting index is just before an element.
  # Additionally, an empty array is returned when the starting index for an element range is at the end of the collection.
  # Returns nil if the index (or starting index) are out of range.
  # ==== Attributes
  #
  # * +index_or_range+ - Either an integer for single element selection or length selection, or a range.
  #
  # ==== Options
  #
  # * +:length+ - The number of elements to return if index_or_range is not a range.
  def [](index_or_range, length=nil)
    # TODO: Consider changing this to return HugeCollection
    if index_or_range.is_a?(Range)
      range = index_or_range
      index = nil
    else
      index = index_or_range.to_i
      range = nil
    end

    if range
      index = range.first
      index += size if index < 0

      length = range.last - index + 1
      length += size if range.last < 0
      length = size - index if index + length > size

      if index < 0 || index > size
        nil
      elsif length < 0
        []
      else
        element_or_array(length) { |i| _fetch(i + index) }
      end
    elsif length
      index += size if index < 0
      length = size - index if index + length > size
      if index < 0 || length < 0
        nil
      else
        element_or_array(length) { |i| _fetch(i + index) }
      end
    else
      _fetch(index)
    end

  end

  # Calls the given block once for each element remaining in the collection, passing that element as a parameter.
  def collection_each(&block) # :yields: element
    # TODO: Return an Enumerator if no block is given
    size.times { |i| yield _fetch(i) }
  end

  # When invoked with a block, yields all combinations of length n of elements from the collection and then returns the collection itself.
  # If no block is given, an HugeCombination is returned instead.
  # === Caveat
  # max_array_size is currently inherited by the generated HugeCombination. This may change in the future.
  def combination(n, &block) # :yields: element
    # Check to see if we have a specific random number generator to use.
    # Using hash comparison as dups, clones, and other actions can make == and eql? return false when it is actually the same method
    random_number_generator = rng.hash != method(:rand).hash ? rng : nil
    combo = HugeCombination.new(self.clone.reset!, n, max_array_size, random_number_generator)
    if block
      combo.each(&block)
      self
    else
      combo
    end
  end

  # Calls the given block once for each element in the next array of the collection, passing that element as a parameter.
  def each(&block) # :yields: element
    # TODO: Return an Enumerator if no block is given
    remaining_or(max_array_size).times(&(block << method(:_fetch)))
    # remaining_or(max_array_size).times { |i| yield _fetch(i) }
  end

  def initialize_copy(orig)
    super
    @rng = @rng.unbind.bind(self) if @rng.respond_to?(:unbind) # Make sure this is bound to self if it is a method
  end

  def max_array_size #:nodoc:
    @max_array_size ||= [collection_size, DEFAULT_MAX_ARRAY_SIZE].min
  end

  # Shifts max_array_size elements and returns the following array from to_a.
  def next_array
    shift(max_array_size)
    to_a
  end

  # Returns true of the collection contains no more elements.
  def empty?
    @start_of_sequence == @end_of_sequence
  end

  # When invoked with a block, yields all permutations of length n of elements from the collection and then returns the collection itself.
  # If no block is given, a HugePermutation is returned instead.
  # === Caveat
  # max_array_size is currently inherited by the generated HugePermutation. This may change in the future.
  def permutation(n, &block) # :yields: element
    # Check to see if we have a specific random number generator to use.
    # Using hash comparison as dups, clones, and other actions can make == and eql? return false when it is actually the same method
    random_number_generator = rng.hash != method(:rand).hash ? rng : nil
    perm = HugePermutation.new(self.clone.reset!, n, max_array_size, random_number_generator)
    if block
      perm.each(&block)
      self
    else
      perm
    end
  end

  # Removes the last element from the collection and returns it, or nil if the collection is empty.
  # If a number n is given, returns an array of the last n elements (or less).
  def pop(n = nil)
    result = element_or_array(n) { pop1 }
    n  ? result.reverse : result
  end

  # When invoked with a block, yields all combinations of elements from the collection and the other enumerable and then returns the collection itself.
  # If no block is given, a HugeProduct is returned instead.
  # === Caveat
  # max_array_size is currently inherited by the generated HugeProduct. This may change in the future.
  # other_enumerable is duped and reset if it is a HugeEnumerable. This may change in the future.
  def product(other_enumerable, &block) # :yields: element
    other_enumerable = other_enumerable.clone.reset! if other_enumerable.is_a?(HugeEnumerable)
    # Check to see if we have a specific random number generator to use.
    # Using hash comparison as dups, clones, and other actions can make == and eql? return false when it is actually the same method
    random_number_generator = rng.hash != method(:rand).hash ? rng : nil
    prod = HugeProduct.new(self.clone.reset!, other_enumerable, max_array_size, random_number_generator)
    if block
      prod.each(&block)
      self
    else
      prod
    end
  end

  # Choose a random element or n random elements from the collection.
  # The elements are chosen by using random and unique indices into the array in order to ensure
  # that an element does not repeat itself unless the collection already contained duplicate elements.
  # If the collection is empty the first form returns nil and the second form returns an empty array.
  # The optional rng argument will be used as the random number generator.
  def sample(*args)
    if args.size > 2
      raise ArgumentError, "wrong number of arguments (#{args.size} for 2)"
    elsif args.size == 2
      n = args.first
      rng = args.last
    elsif args.size == 1
      arg = args.first
      if arg.is_a?(Proc) || arg.is_a?(Method)
        n = 1
        rng = arg
      else
        n = arg
        rng = method(:rand)
      end
    else
      n = nil
      rng = method(:rand)
    end

    element_or_array(n) { sample1(rng) }
  end

  # Removes the first element of the collection and returns it (shifting all other elements down by one).
  # Returns nil if the collection is empty.
  # If a number n is given, returns an array of the first n elements (or less).
  # With collection containing only the remainder elements, not including what was shifted to returned array.
  # ==== Options
  # * +rng+ - The random number generator to use. Defaults to self#rng.
   def shift(n = nil)
    element_or_array(n) { shift1 }
  end

  # Returns a new HugeEnumerable with the order of the elements of the new collection randomized.
  # ==== Options
  # * +rng+ - The random number generator to use. Defaults to self#rng.
  # ==== Side Effects
  # The new collection is reset to the current collection's original size and elements before shuffling.
  def shuffle(rng=nil)
    self.clone.shuffle!(rng)
  end

  # Randomly reorders the elements of the collection.
  # ==== Options
  # * +rng+ - The random number generator to use. Defaults to self#rng.
  # ==== Side Effects
  # The collection is reset to its original size and elements before shuffling
  def shuffle!(rng=nil)
    rng ||= self.rng
    reset!
    @shuffle_head = rng.call(collection_size)
    @collection_increment = full_cycle_increment(collection_size)
    self
  end

  # Returns the current size of the collection.
  # Unlike collection_size, this tracks size changes caused by push, pop, shift, and next_array.
  def size
    end_of_sequence - start_of_sequence
  end

  protected

  def reset!
    @start_of_sequence = 0
    @end_of_sequence = nil
    self
  end

  private

  attr_reader :shuffle_head, :start_of_sequence, :end_of_sequence, :collection_increment

  def collection_size
    raise NotImplementedError, "not implemented for #{self.class.name}"
  end

  def end_of_sequence
    @end_of_sequence ||= collection_size
  end

  def fetch(x)
    raise NotImplementedError, "not implemented for #{self.class.name}"
  end

  def miller_rabin
    @miller_rabin ||= Prime::MillerRabin.new
  end

  def next_prime(x)
    if x < 2
      2
    elsif x < 3
      3
    elsif x < 5
      5
    else
      x += (x.even? ? 1 : (x % 10 == 3 ? 4 : 2 ))
      x += (x % 10 == 3 ? 4 : 2 ) until Prime.prime?(x, miller_rabin)
      x
    end
  end

  def pop1
    result = _fetch(end_of_sequence - start_of_sequence - 1)
    @end_of_sequence -= 1
    result
  end

  def remaining_or(x)
    [x, size].min
  end

  def shuffle_index(index)
    index ? (shuffle_head + collection_increment * index) % collection_size : nil
  end

  def relative_index(index)
    index = end_of_sequence + index if index < 0
    index += start_of_sequence
    index >= 0 && index < end_of_sequence ? index : nil
  end

  def shift1
    result = _fetch(0)
    @start_of_sequence += 1
    result
  end

  def _fetch(index)
    index = shuffle_index(relative_index(index))
    index ? fetch(index) : nil
  end

  def sample1(rng)
    if @sample_position.nil? || @sample_position >= size
      @sample_position = rng.call(size)
    else
      if @last_sample_size != size
        @last_sample_size = size
        @sample_increment = full_cycle_increment(size)
      end
      @sample_position = (@sample_position + @sample_increment) % size
    end
    _fetch(@sample_position)
  end

  def full_cycle_increment(domain_size)
    increment = next_prime(( 2 * domain_size / (1 + Math.sqrt(5)) ).to_i)
    increment == domain_size ? next_prime(increment + 1) : increment
  end

  def factorial(x)
    x == 0 ? 1 : (1..x).reduce(:*)
  end


  def element_or_array(n = nil)
    unless n.nil?
      n = n.to_i
      raise ArgumentError, 'negative array size' if n < 0
    end
    unless empty?
      n ? (0...remaining_or(n)).map { |x| yield(x) } : yield
    else
      n.nil? ? nil : []
    end
  end

end

require 'huge_enumerable/huge_collection'
require 'huge_enumerable/huge_combination'
require 'huge_enumerable/huge_permutation'
require 'huge_enumerable/huge_product'



