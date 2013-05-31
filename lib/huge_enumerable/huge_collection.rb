require 'huge_enumerable'

class HugeCollection < HugeEnumerable

  def initialize(enumerable, max_array_size = nil, rng = nil)
    @enum = enumerable
    super(max_array_size, rng)
  end

  def collection_size
    enum_size
  end

  def fetch(x)
    enum[x]
  end

  private

  attr_accessor :enum

  def enum_size
    @enum_size ||= enum.size
  end

end
