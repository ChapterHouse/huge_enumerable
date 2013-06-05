require 'huge_enumerable'
# The simplest form of a HugeEnumerable.
# This class can be used for large arrays or anything else that responds to [].
# It is not necessary for the enumerable to be completely mapped into memory.
# It only has to be able to return the element mapped to the index given to [].
# ==== Examples
#
# Using HugeCollection directly:
#
#    original_array = ('a'..'z').to_a
#    collection = HugeCollection.new(original_array)
#    collection.shuffle!
#    original_array[0..4] # => ["a", "b", "c", "d", "e"]
#    collection[0..4] # => ["j", "a", "r", "i", "z"]
#
#
# Subclassing HugeCollection
#
#    class StringNext < HugeCollection
#
#      def initialize(size)
#        @collection_size = size
#        super ('a'..'z').to_a
#      end
#
#      private
#
#      def fetch(index)
#        result = ""
#        index += 1
#        while index > 0
#          index -= 1
#          result.prepend super(index % 26)
#          index /= 26
#        end
#        result
#      end
#
#    end
#
#    googol = 10*100
#    collection = StringNext.new(googol)
#    collection.size # => 10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
#    collection[0]          # => "a"
#    collection[-1]         # => "zhxrtplbmwaiwcqlzpmglpziaegsdivmbvlnssusbjtbcgywaycqnhxztqwwikxvrsptazpp"
#    collection[googol / 2] # => "dlijhfafxmqxnusmhfpshmdmopvodxfnkfgivwvnejaapyxmynutdlmjhxxqrykiiuizzhi"
#    collection.shuffle!
#    collection[0]          # => "bipzqqzayczkgsmaseflwktpsotzclcjsqlnnjaciaawufpojywxflknuddhqkilhoedacn"
#    collecyion[-1]         # => "etneuebyurxgrvrfsreesxuvjaiyoqwplofsptacjdbhuhafdiwbwujvniokltgkjbfkiuy"
class HugeCollection < HugeEnumerable

  # Create a new HugeCollection
  #
  # ==== Attributes
  #
  # * +enumerable+ - Any enumerable that responds to []
  #
  # ==== Options
  #
  # * +:max_array_size+ - The default size of arrays when #to_a is called.
  # * +:rng+ - The random number generator to use.
  def initialize(enumerable, max_array_size = nil, rng = nil)
    @enum = enumerable
    super(max_array_size, rng)
  end

  private

  attr_accessor :enum

  def collection_size
    @collection_size ||= enum_size
  end

  def enum_size
    @enum_size ||= enum.size
  end

  def fetch(index)
    enum[index]
  end

end
