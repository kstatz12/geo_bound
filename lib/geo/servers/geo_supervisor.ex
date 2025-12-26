# coveralls -ignore-start
defmodule Geo.Servers.GeoSupervisor do
  @moduledoc """
  supervisor for data server(s)
  """

  use Supervisor

  alias Geo.Servers.QueryServer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    data_file_path =
      Application.get_env(
        :geo,
        :data_file_path,
        Path.join(:code.priv_dir(:geo), "data/geonames.json")
      )

    children = [
      {QueryServer, %{data_file_path: data_file_path}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

# coveralls-ignore-stop
