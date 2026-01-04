defmodule Geo.Servers.GeoHashQueryServer do
  @moduledoc """
  server to handle queries and hold table definition for geohash queries
  """

  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  @impl true
  def init(opts) do
    tid = :ets.new(:geo_hash_data_table, [:bag, :public, read_concurrency: true])
  end
end
