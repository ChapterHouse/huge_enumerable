require 'huge_enumerable'
# HugeCombination is a HugeEnumerable style combination. Comparable to Array#combination.
# This class can be used to generate combinations of large arrays or anything else that responds to [].
# It is not necessary for the enumerable to be completely mapped into memory.
# It only has to be able to return the element mapped to the index given to [].
# ==== Examples
#
# Using HugeCombination directly:
#
#    combination = HugeCombination.new(('a'..'z').to_a, 2)
#    combination[0..4] # => [["a", "b"], ["a", "c"], ["a", "d"], ["a", "e"], ["a", "f"]]
#    combination[23..27] # => [["a", "y"], ["a", "z"], ["b", "c"], ["b", "d"], ["b", "e"]]
#
#
# Subclassing HugeCombination
#
#    class NumberArray < HugeCollection
#
#      def initialize(size)
#        @collection_size = size
#        super(nil)
#      end
#
#      private
#
#      def fetch(index)
#        index
#      end
#
#    end
#
#    class NumberCombination < HugeCombination
#
#      def initialize(size)
#        enumerable = size < 10 ? (0...size).to_a : NumberArray.new(size)
#        super enumerable, 2, nil, nil
#      end
#
#      private
#
#      def fetch(index)
#        array = super
#        sum = array.inject(0) { |sum, i| sum += i }
#        "#{array.first} + #{array.last} = #{sum}"
#      end
#
#    end
#
#    combination = NumberCombination.new(10**30)
#    size = combination.size # => 499999999999999999999999999999500000000000000000000000000000
#    combination[0]          # => "0 + 1 = 1"
#    combination[-1]         # => "999999999999999999999999999998 + 999999999999999999999999999999 = 1999999999999999999999999999997"
#    combination[size / 2]   # => "292893218813452475599155637895 + 296085173605458049080913472356 = 588978392418910524680069110251"
class HugeCombination < HugeCollection

  # Create a new HugeCombination
  #
  # ==== Attributes
  #
  # * +enumerable+ - Any enumerable that responds to []
  # * +size+ - The number of elements per combination to use from enumerable.
  #
  # ==== Options
  #
  # * +:max_array_size+ - The default size of arrays when #to_a is called.
  # * +:rng+ - The random number generator to use.
  def initialize(enumerable, size, max_array_size = nil, rng = nil)
    @combination_size = size
    super(enumerable, max_array_size, rng)
  end

  private

  attr_reader :combination_size

  def collection_size
    @collection_size ||= size_of_combination(enum_size, combination_size)
  end

  def fetch(index)
    indexes_for(collection_size - index - 1).map { |i| enum[enum_size - i - 1] }
  end

  def size_of_combination(n, k)
    k < 0 || n < k ? 0 : factorial(n)/(factorial(k) * factorial(n - k))
  end

  def indexes_for(position)
    k = combination_size
    indexes = []
    while k > 0
      n, size = next_n_and_size(position, k)
      position -= size
      k -= 1
      indexes << n
    end
    indexes
  end

  def next_n_and_size(p, k)
    n = k - 1
    size = size_of_combination(n, k)
    begin
      rc = [n, size]
      n += 1
      size = size_of_combination(n, k)
    end while size <= p
    rc
  end

end

