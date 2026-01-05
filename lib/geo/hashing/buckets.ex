defmodule Geo.Hashing.Buckets do
  @moduledoc """
    bucket/geohash helpers
  """

  # ring=0 => prefix only
  # ring=1 => prefix + 8 neighbors
  # ring=2 => neighbors-of-neighbors (a 2-step ring)
  def buckets_for(point, precision, ring) do
    prefix = Geohash.encode(point, precision)

    case ring do
      0 ->
        [prefix]

      1 ->
        [prefix | Geohash.neighbors(prefix)]
        |> Enum.uniq()

      _ ->
        expand_rings([prefix], ring)
    end
  end

  defp expand_rings(seeds, ring) do
    Enum.reduce(1..ring, MapSet.new(seeds), fn _step, set ->
      set
      |> Enum.flat_map(fn b -> [b | Geohash.neighbors(b)] end)
      |> MapSet.new()
    end)
    |> MapSet.to_list()
  end
end
