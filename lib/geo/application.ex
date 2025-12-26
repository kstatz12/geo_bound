defmodule Geo.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Geo.Servers.GeoSupervisor
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Geo.Supervisor
    )
  end
end
