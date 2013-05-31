require 'huge_enumerable'

class HugeProduct < HugeEnumerable

  def initialize(enumerable_a, enumerable_b, max_array_size = nil, rng = nil)
    @enum_a = enumerable_a
    @enum_b = enumerable_b
    super(max_array_size, rng)
  end

  def fetch(x)
    [enum_a[x / enum_b_size], enum_b[x % enum_b_size]]
  end

  def collection_size
    enum_a_size * enum_b_size
  end

  private

  attr_accessor :enum_a, :enum_b

  def enum_a_size
    @enum_a_size ||= enum_a.size
  end

  def enum_b_size
    @enum_b_size ||= enum_b.size
  end

end
