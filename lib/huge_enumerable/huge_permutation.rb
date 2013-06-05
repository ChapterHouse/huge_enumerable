require 'huge_enumerable'
# HugePermutation is a HugeEnumerable style permutation. Comparable to Array#permutation.
# This class can be used to generate permutations of large arrays or anything else that responds to [].
# It is not necessary for the enumerable to be completely mapped into memory.
# It only has to be able to return the element mapped to the index given to [].
# ==== Examples
#
# Using HugePermutation directly:
#
#    permutation = HugePermutation.new(('a'..'z').to_a, 2)
#    permutation[0..4]   # => [["a", "b"], ["a", "c"], ["a", "d"], ["a", "e"], ["a", "f"]]
#    permutation[23..27] # => [["a", "y"], ["a", "z"], ["b", "a"], ["b", "c"], ["b", "d"]]
#
#
# Subclassing HugePermutation
#
#    class SouthernNames < HugePermutation
#
#      def initialize
#        base_names = %w{Bill Joe Jo Bob Mary Lou Betty Sue Jimmy Ann Lee Ruby Jack Belle Daisy Dixie Lynn}
#        super base_names, 2, nil, nil
#      end
#
#      private
#
#      def fetch(index)
#        "Your southern name is: #{super(index).join(' ')}"
#      end
#
#    end
#
#    southern_name = SouthernNames.new
#    southern_name[0]          # => "Your southern name is: Bill Joe"
#    southern_name[-1]         # => "Your southern name is: Lynn Dixie"
#    size = southern_name.size # => 272
#    southern_name[size / 2]   # => "Your southern name is: Jimmy Ann"
class HugePermutation < HugeCollection

  # Create a new HugePermutation
  #
  # ==== Attributes
  #
  # * +enumerable+ - Any enumerable that responds to []
  # * +size+ - The number of elements per permutation to use from enumerable. (Currently only size 2 is supported)
  #
  # ==== Options
  #
  # * +:max_array_size+ - The default size of arrays when #to_a is called.
  # * +:rng+ - The random number generator to use.
  def initialize(enumerable, length, max_array_size = nil, rng = nil)
    raise NotImplementedError, "Not yet implemented for any length != 2" if length != 2 # TODO: Extend this class to handle length N
    super(enumerable, max_array_size, rng)
  end

  private

  def fetch(x)
    first_index = x / (enum_size - 1)
    second_index = ((x % enum_size) + (x / enum_size + 1)) % enum_size
    [enum[first_index], enum[second_index]]
  end

  def collection_size
    enum_size * (enum_size - 1)
  end

end
