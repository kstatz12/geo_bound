defmodule Geo.Servers.QueryServer do
  @moduledoc """
    server for holding geo ets table and facilitating queries
  """

  require Logger
  use GenServer

  def query(match_spec) do
    table_name = Application.get_env(:geo, :geo_table_name, :geo_data_table)
    :ets.select(table_name, match_spec)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  @impl true
  def init(opts) do
    table_name = Application.get_env(:geo, :geo_table_name, :geo_data_table)

    :ets.new(table_name, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true}
    ])

    path = Map.get(opts, :data_file_path) || Application.get_env(:geo, :data_file_path)

    {:ok, %{status: :initialized, table_name: table_name}, {:continue, {:load, path}}}
  end

  @impl true
  def handle_continue({:load, file_path}, state) do
    file_path
    |> File.read!()
    |> Poison.decode!(keys: :atoms)
    |> Enum.each(fn r -> :ets.insert(state.table_name, {UUID.uuid4(), r}) end)

    {:noreply, %{state | status: :loaded}}
  end
end
