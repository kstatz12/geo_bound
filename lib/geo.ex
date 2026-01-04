defmodule Geo do
  @moduledoc """
    geo library
  """

  alias Geo.Filter.Radius
  alias Geo.Math.{ConvexHull, Fence}
  alias Geo.Queries
  alias Geo.Servers.QueryServer

  @spec city_fence(String.t(), String.t(), {number(), number()}) :: boolean()
  def city_fence(city_name, state_code, loc) do
    Queries.postal_code_in_city(city_name, String.upcase(state_code))
    |> QueryServer.query()
    |> ConvexHull.convex_hull()
    |> Fence.contains_point?(loc)
  end


 
end
