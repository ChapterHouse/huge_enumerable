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
  # * +size+ - The number of elements per combination to use from enumerable. (Currently only size 2 is supported)
  #
  # ==== Options
  #
  # * +:max_array_size+ - The default size of arrays when #to_a is called.
  # * +:rng+ - The random number generator to use.
  def initialize(enumerable, size, max_array_size = nil, rng = nil)
    raise NotImplementedError, "Not yet implemented for any size != 2" if size != 2 # TODO: Extend this class to handle length N
    @combination_size = size
    super(enumerable, max_array_size, rng)
  end

  private

  def collection_size
    sum(enum_size - 1)
  end

  def fetch(index)
    cycle = locate_cycle(index)
    first_index = cycle - 1
    max_cycles = enum_size - 1
    used = (cycle - 1) == 0 ? 0 : sum_from(max_cycles, max_cycles - (cycle - 2))
    second_index = index - used + cycle
    [enum[first_index], enum[second_index]]
  end

  def locate_cycle(index, min=0, max=enum_size-1)
    cycle = min + (max - min) / 2

    check_high = sum_at_cycle(cycle)
    check_low = sum_at_cycle(cycle - 1)

    if check_high > index && check_low <= index
      cycle
    elsif check_low > index
      locate_cycle(index, min, cycle-1)
    else
      locate_cycle(index, cycle+1, max)
    end
  end

  def sum(x)
    x * (x + 1) / 2
  end

  def sum_from(m, n)
    m, n = [n, m] if m > n
    (n + 1 - m)*(n + m)/2
  end

  def sum_at_cycle(c)
    ec = enum_size * c
    (-c + 2*ec - c**2)/2
  end

end

