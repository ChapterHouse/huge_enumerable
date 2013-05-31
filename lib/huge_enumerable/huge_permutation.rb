require 'huge_enumerable'

class HugePermutation < HugeCollection

  def initialize(enumerable, length, max_array_size = nil, rng = nil)
    raise NotImplemented, "Not yet implemented for any length != 2" if length != 2 # TODO: Extend this class to handle length N
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
