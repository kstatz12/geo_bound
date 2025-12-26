defmodule Geo.Servers.QueryServer do
  @moduledoc """
    server for holding geo ets table and facilitating queries
  """

  alias Geo.Data

  require Logger
  use GenServer

  def query(match_spec, pid \\ __MODULE__) do
    do_wait_for_loaded(pid)

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

    Process.send_after(self(), {:load, path}, 500)

    {:ok, %{status: :initialized, table_name: table_name}}
  end

  @impl true
  def handle_info({:load, file_path}, state) do
    do_prepare_data(file_path)
    |> Enum.each(fn r -> :ets.insert(state.table_name, {UUID.uuid4(), r}) end)

    {:noreply, %{state | status: :loaded}}
  end

  @impl true
  def handle_call(:check_ready, _from, state) do
    {:reply, state.status, state}
  end

  defp do_prepare_data(path) when is_binary(path),
    do: path |> to_charlist() |> Data.load!() |> Data.parse!()

  defp do_prepare_data(path) when is_list(path), do: path |> Data.load!() |> Data.parse!()

  defp do_wait_for_loaded(pid, retries \\ 50)

  defp do_wait_for_loaded(_pid, 0), do: raise("geo data failed to load within timeout")

  defp do_wait_for_loaded(pid, retries) do
    case GenServer.call(pid, :check_ready) do
      :loaded ->
        :ok

      _ ->
        Process.sleep(100)
        do_wait_for_loaded(pid, retries - 1)
    end
  end
end
