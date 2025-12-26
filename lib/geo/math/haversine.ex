defmodule Geo.Math.Haversine do
  @moduledoc """
  Calculate the great-circle distance between two points on Earth
  using the Haversine formula.
  """

  @earth_radius_km 6371.0
  @earth_radius_miles 3959.0

  @doc """
  Calculate distance between two geographic points in kilometers.

  ## Parameters
  - lat1, lon1: Latitude and longitude of first point (in degrees)
  - lat2, lon2: Latitude and longitude of second point (in degrees)

  ## Examples

      iex> Haversine.distance_km(40.7128, -74.0060, 51.5074, -0.1278)
      5570.27
  """
  def distance_km(lat1, lon1, lat2, lon2) do
    calculate_distance(lat1, lon1, lat2, lon2, @earth_radius_km)
  end

  @doc """
  Calculate distance between two geographic points in miles.

  ## Parameters
  - lat1, lon1: Latitude and longitude of first point (in degrees)
  - lat2, lon2: Latitude and longitude of second point (in degrees)

  ## Examples

      iex> Haversine.distance_miles(40.7128, -74.0060, 51.5074, -0.1278)
      3461.34
  """
  def distance_miles(lat1, lon1, lat2, lon2) do
    calculate_distance(lat1, lon1, lat2, lon2, @earth_radius_miles)
  end

  defp calculate_distance(lat1, lon1, lat2, lon2, radius) do
    lat1 = to_float_default(lat1, 0.0)
    lon1 = to_float_default(lon1, 0.0)
    lat2 = to_float_default(lat2, 0.0)
    lon2 = to_float_default(lon2, 0.0)
    radius = to_float_default(radius, 0.0)

    lat1_rad = deg2rad(lat1)
    lon1_rad = deg2rad(lon1)
    lat2_rad = deg2rad(lat2)
    lon2_rad = deg2rad(lon2)

    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) *
          :math.pow(:math.sin(dlon / 2), 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    (radius * c)
    |> Float.round(2)
  end

  defp deg2rad(degrees), do: degrees * :math.pi() / 180.0

  defp to_float_default(v, default) do
    case to_float(v) do
      {:ok, f} -> f
      :error -> default
    end
  end

  defp to_float(nil), do: :error
  defp to_float(v) when is_float(v), do: {:ok, v}
  defp to_float(v) when is_integer(v), do: {:ok, v * 1.0}

  defp to_float(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> {:ok, f}
      :error -> :error
    end
  end

  defp to_float(_), do: :error
end
