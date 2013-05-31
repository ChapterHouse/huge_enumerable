require 'huge_enumerable'

class HugePermutation2 < HugeCollection

  def initialize(enumerable, max_array_size = nil, rng = nil)
    super(enumerable, max_array_size, rng)
  end

  def fetch(x)
    first_index = x / (enum_size - 1)
    second_index = ((x % enum_size) + (x / enum_size + 1)) % enum_size
    [enum[first_index], enum[second_index]]
  end

  def collection_size
    enum_size * (enum_size - 1)
  end

end
