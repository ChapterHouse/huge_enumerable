require 'huge_enumerable'
# HugePermutation is a HugeEnumerable style product. Comparable to Array#product.
# This class can be used to generate products of large arrays or anything else that responds to [].
# It is not necessary for the enumerables to be completely mapped into memory.
# They only have to be able to return the element mapped to the index given to [].
# ==== Examples
#
# Using HugeProduct directly:
#
#    product = HugeProduct.new(('a'..'z').to_a, ('A'..'Z').to_a)
#    product[0..4]   # => [["a", "A"], ["a", "B"], ["a", "C"], ["a", "D"], ["a", "E"]]
#    product[23..27] # => [["a", "X"], ["a", "Y"], ["a", "Z"], ["b", "A"], ["b", "B"]]
#
#
# Subclassing HugeProduct
#
#    class BabyGirlNames < HugeProduct
#
#      def initialize
#        first_names = %w{Emma Olivia Sophia Isabella Ava Mia Emily Charlotte Ella Amelia Abigail Madison Lily Chloe}
#        middle_names = %w{Zoe Sophie Evelyn Aubrey Elizabeth Layla Anna Natalie Brooklyn Aria Audrey Ellie Lucy}
#        super(first_names, middle_names)
#      end
#
#      private
#
#      def fetch(index)
#        super(index).join(' ')
#      end
#
#    end
#
#    name = BabyGirlNames.new
#    name[0]          # => "Emma Zoe"
#    name[-1]         # => "Chloe Lucy"
#    size = name.size # => 182
#    name[size / 2]   # => "Charlotte Zoe"
class HugeProduct < HugeEnumerable

  # Create a new HugeProduct
  #
  # ==== Attributes
  #
  # * +enumerable_a+ - Any enumerable that responds to []
  # * +enumerable_b+ - Any enumerable that responds to [] (This can be the same object as enumerable_a)
  #
  # ==== Options
  #
  # * +:max_array_size+ - The default size of arrays when #to_a is called.
  # * +:rng+ - The random number generator to use.
  def initialize(enumerable_a, enumerable_b, max_array_size = nil, rng = nil)
    @enum_a = enumerable_a
    @enum_b = enumerable_b
    super(max_array_size, rng)
  end

  private

  attr_accessor :enum_a, :enum_b

  def collection_size
    enum_a_size * enum_b_size
  end

  def fetch(x)
    [enum_a[x / enum_b_size], enum_b[x % enum_b_size]]
  end

  def enum_a_size
    @enum_a_size ||= enum_a.size
  end

  def enum_b_size
    @enum_b_size ||= enum_b.size
  end

end
