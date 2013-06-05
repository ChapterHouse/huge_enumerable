require 'huge_enumerable'

# HugeCombintion is a HugeEnumerable style combination. Comparable to Array#combination.
# This class can be used to generate combinations of large arrays or anything else that responds to [].
# It is not necessary for the enumerable to be completely mapped into memory.
# It only has to be able to return the element mapped to the index given to [].
# ==== Examples
#
# Using HugeCombination directly:
#
#    combination = HugeCombination.new(('a'..'z').to_a, 2)
#    combination[0..4] # => [["a", "b"], ["a", "c"], ["a", "d"], ["a", "e"], ["a", "f"]]
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
#      def fetch(index)
#        index
#      end
#
#    end
#
#    class NumberPermutation < HugeCombination
#
#      def initialize(size)
#        enumerable = size < 10 ? (0...size).to_a : NumberArray.new(size)
#        super enumerable, 2, nil, nil
#      end
#
#      def fetch(index)
#        array = super
#        sum = array.inject(0) { |sum, i| sum += i }
#        "#{array.first} + #{array.last} = #{sum}"
#      end
#
#    end
#
#    combination = NumberPermutation.new(10**30)
#    combination.size # => 499999999999999999999999999999500000000000000000000000000000
#

#
#    combination = StringNextCombination.new(10*30)
#    collection.size # => 10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
#    collection[0]          # => "a"
#    collection[-1]         # => "zhxrtplbmwaiwcqlzpmglpziaegsdivmbvlnssusbjtbcgywaycqnhxztqwwikxvrsptazpp"
#    collection[googol / 2] # => "dlijhfafxmqxnusmhfpshmdmopvodxfnkfgivwvnejaapyxmynutdlmjhxxqrykiiuizzhi"
#    collection.shuffle!
#    collection[0]          # => "bipzqqzayczkgsmaseflwktpsotzclcjsqlnnjaciaawufpojywxflknuddhqkilhoedacn"
#    collecyion[-1]         # => "etneuebyurxgrvrfsreesxuvjaiyoqwplofsptacjdbhuhafdiwbwujvniokltgkjbfkiuy"
class HugeCombination < HugeCollection

  def initialize(enumerable, length, max_array_size = nil, rng = nil)
    raise NotImplementedError, "Not yet implemented for any length != 2" if length != 2 # TODO: Extend this class to handle length N
    @length = length
    super(enumerable, max_array_size, rng)
  end

  # Returns the size of the original combination before modification.
  #
  # ==== Examples
  #
  #    combination = HugeCombination.new(('a'..'z').to_a, 2)
  #    combination.collection_size # => 325
  def collection_size
    sum(enum_size - 1)
  end

  # Returns the element of the combination at the specified index
  #
  # ==== Attributes
  #
  # * +index+ - The index of the element
  #
  # ==== Examples
  #
  #    combination = HugeCombination.new(('a'..'z').to_a, 2)
  #    combination.fetch[17] # => ["a", "s"]
  def fetch(index)
    cycle = locate_cycle(index)
    first_index = cycle - 1
    max_cycles = enum_size - 1
    used = (cycle - 1) == 0 ? 0 : sum_from(max_cycles, max_cycles - (cycle - 2))
    second_index = index - used + cycle
    [enum[first_index], enum[second_index]]
  end


  private

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
