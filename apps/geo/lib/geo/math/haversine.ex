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
    lat1_rad = degrees_to_radians(lat1)
    lon1_rad = degrees_to_radians(lon1)
    lat2_rad = degrees_to_radians(lat2)
    lon2_rad = degrees_to_radians(lon2)

    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) *
          :math.pow(:math.sin(dlon / 2), 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    distance = radius * c
    Float.round(distance, 2)
  end

  defp degrees_to_radians(degrees) do
    degrees * :math.pi() / 180
  end
end
