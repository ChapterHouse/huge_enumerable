require 'huge_enumerable'

class HugeCombination < HugeCollection

  def initialize(enumerable, length, max_array_size = nil, rng = nil)
    raise NotImplemented, "Not yet implemented for any length != 2" if length != 2 # TODO: Extend this class to handle length N
    super(enumerable, max_array_size, rng)
  end

  def collection_size
    sum(enum_size - 1)
  end

  def fetch(x)
    cycle = 1
    while sum_from(enum_size - 1, enum_size - cycle) < x + 1
      cycle += 1
    end
    first_index = cycle - 1

    max_cycles = enum_size - 1
    used = (cycle - 1) == 0 ? 0 : sum_from(max_cycles, max_cycles - (cycle - 2))
    second_index = x - used + cycle

    [enum[first_index], enum[second_index]]
  end

  private

  def sum(x)
    x * (x + 1) / 2
  end

  def sum_from(b, a)
    a, b = [b, a] if a > b
    sum(b) - sum(a-1)
  end

end
