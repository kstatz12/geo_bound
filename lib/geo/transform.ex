defmodule Geo.Transform  do
  @moduledoc """
    transoforms raw structs from ets to maps
  """

  def handle({lat, lng}), do: %{latitude: lat, longitude: lng}

  def handle({lat, lng, an}), do: %{latitude: lat, longitude: lng, alt_name: an}

  def handle({cn, sc, lat, lng}), do: %{city_name: cn, state_code: sc, latitude: lat, longitude: lng}
end
