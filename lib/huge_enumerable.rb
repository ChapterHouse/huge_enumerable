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

  DEFAULT_MAX_ARRAY_SIZE=10000

  attr_accessor :max_array_size, :rng

  def initialize(max_array_size = nil, rng = nil)
    @max_array_size = max_array_size ? max_array_size.to_i : nil
    @rng = self.method(:rand)
    @collection_increment = 1
    @start_of_sequence = 0
    @shuffle_head = 0
  end

  def [](index_or_range, length=nil)
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

  def each(&block)
    remaining_or(max_array_size).times { |i| yield _fetch(i) }
  end

  def max_array_size
    @max_array_size ||= [collection_size, DEFAULT_MAX_ARRAY_SIZE].min
  end

  def next_array
    shift(max_array_size)
    to_a
  end

  def empty?
    @start_of_sequence == @end_of_sequence
  end

  def pop(n = nil)
    result = element_or_array(n) { pop1 }
    n  ? result.reverse : result
  end

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

  def shift(n = nil)
    element_or_array(n) { shift1 }
  end

  def shuffle(rng=nil)
    self.dup.shuffle!(rng)
  end

  def shuffle!(rng=nil)
    rng ||= self.rng
    @start_of_sequence = 0
    @end_of_sequence = nil
    @shuffle_head = rng.call(collection_size)
    @collection_increment = full_cycle_increment(collection_size)
    self
  end

  def size
    end_of_sequence - start_of_sequence
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



