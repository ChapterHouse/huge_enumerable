require "huge_enumerable/version"

require 'backports' if RUBY_VERSION < '1.9'
require 'prime'

class HugeEnumerable

  include Enumerable

  DEFAULT_MAX_ARRAY_SIZE=10000

  attr_accessor :max_array_size
  attr_accessor :rng

  def initialize(max_array_size = nil, rng = nil)
    @max_array_size = max_array_size ? max_array_size.to_i : nil
    @rng = self.method(:rand)
    @iterator = 1
    @start_of_sequence = 0
    @shuffle_head = 0
  end

  def [](x)
    # TODO: Support a range
    # TODO: Support second length parameter
    # Consider returning HugeCollections?
    _fetch(x)
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
    unless n.nil?
      n = n.to_i
      raise ArgumentError, 'negative array size' if n < 0
    end
    unless empty?
      n ? (0...remaining_or(n)).map { pop1 }.reverse : pop1
    else
      n.nil? ? nil : []
    end
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

    unless n.nil?
      n = n.to_i
      raise ArgumentError, 'negative array size' if n < 0
    end
    unless empty?
      n ? (0...remaining_or(n)).map { sample1(rng) } : sample1(rng)
    else
      n.nil ? nil : []
    end

  end

  def shift(n = nil)
    unless n.nil?
      n = n.to_i
      raise ArgumentError, 'negative array size' if n < 0
    end
    unless empty?
      n ? (0...remaining_or(n)).map { shift1 } : shift1
    else
      n.nil? ? nil : []
    end
  end

  def shuffle(rng=nil)
    self.dup.shuffle!(rng)
  end

  def shuffle!(rng=nil)
    rng ||= self.rng
    @start_of_sequence = 0
    @end_of_sequence = nil
    @shuffle_head = rng.call(collection_size)
    @iterator = next_prime(( 2 * collection_size / (1 + Math.sqrt(5)) ).to_i)
    self
  end

  def size
    end_of_sequence - start_of_sequence
  end

  private

  attr_reader :shuffle_head
  attr_reader :index, :start_of_sequence, :end_of_sequence

  def collection_size
    raise NotImplementedError, "not implemented for #{self.class.name}"
  end

  def end_of_sequence
    @end_of_sequence ||= collection_size
  end

  def fetch(x)
    raise NotImplementedError, "not implemented for #{self.class.name}"
  end

  def iterator
    @iterator
  end

  def next_index
    self.index = (index + iterator) % collection_size
  end

  def previous_index
    self.index = (index - iterator) % collection_size
  end

  def next_prime(x)
    x = x + (x.even? ? 1 : 2)
    x += 2 until x.prime?
    x
  end

  def pop1
    result = _fetch(end_of_sequence - start_of_sequence - 1)
    @end_of_sequence -= 1
    result
  end

  def remaining_or(x)
    [x, size].min
  end

  def shuffle_index(regular_index)
    (shuffle_head + iterator * regular_index) % collection_size
  end

  def shift1
    result = _fetch(0)
    @start_of_sequence += 1
    result
  end

  def _fetch(i)
    i += start_of_sequence

    if i >= end_of_sequence || i < -size
      nil
    else
      fetch(shuffle_index(i))
    end
  end

  def sample1(rng)
    if @sample_position.nil? || @sample_position >= size
      @sample_position = rng.call(size)
    else
      @sample_position = (@sample_position + next_prime(( 2 * size / (1 + Math.sqrt(5)) ).to_i)) % size
    end
    _fetch(@sample_position)
  end

end

require 'huge_enumerable/huge_collection'
require 'huge_enumerable/huge_combination'
require 'huge_enumerable/huge_permutation'
require 'huge_enumerable/huge_product'


