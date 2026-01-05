defmodule Geo.Servers.GeoHashQueryServer do
  @moduledoc """
  server to handle queries and hold table definition for geohash queries
  """

  alias Geo.Math.Haversine
  alias Geo.Hashing.Buckets

  require Logger
  use GenServer

  def nearest(loc, opts) do
    precision = opts[:geo_hash_precision] || Application.get_env(:geo, :geo_hash_precision, 6)

    max_ring =
      opts[:geo_hash_max_ring_depth] || Application.get_env(:geo, :geo_hash_max_ring_depth, 2)

    Enum.reduce_while(0..max_ring, nil, fn ring, _acc ->
      buckets = Buckets.buckets_for(loc, precision, ring)

      cands =
        buckets
        |> Enum.flat_map(fn b ->
          :ets.lookup(:geo_hash_data_table, b) |> Enum.map(fn {^b, rec} -> rec end)
        end)

      case best_candidates(loc, cands) do
        nil -> {:cont, nil}
        best -> {:halt, best}
      end
    end)
  end

  defp best_candidates(_loc, []), do: nil

  defp best_candidates({lat1, lng1}, recs) do
    Enum.reduce(recs, nil, fn {zip, lat2, lng2} = rec, acc ->
      d = Haversine.distance_km(lat1, lng1, lat2, lng2)

      case acc do
        nil -> {rec, d}
        {_best, best_d} when d < best_d -> {rec, d}
        _ -> acc
      end
    end)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  @impl true
  def init(opts) do
    tid = :ets.new(:geo_hash_data_table, [:bag, :public, read_concurrency: true])

    path =
      Map.get(opts, :geo_hash_data_file_path) ||
        Application.get_env(:geo, :geo_hash_data_file_path)

    {:ok, %{status: :initialized, table: tid}, {:continue, {:load, path}}}
  end

  @impl true
  def handle_continue({:load, path}, state) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.each(fn {bucket, recs} ->
      Enum.each(recs, fn [zip, lat, lng] ->
        # store as tuple for cheap pattern match
        :ets.insert(Map.get(state, :table), {bucket, {zip, lat, lng}})
      end)
    end)

    {:noreply, %{state | status: :loaded}}
  end
end
