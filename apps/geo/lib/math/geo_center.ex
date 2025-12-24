defmodule Geo.Math.GeoCenter do
  @moduledoc """
   finding the averaged center of an arbitrary list of lat/lngs``
  """
  def deg2rad(deg), do: deg * :math.pi() / 180
  def rad2deg(rad), do: rad * 180 / :math.pi()

  def center(coords) do
    count = length(coords)

    {x, y, z} =
      Enum.reduce(coords, {0.0, 0.0, 0.0}, fn {lat, lng}, {x_acc, y_acc, z_acc} ->
        lat_rad = deg2rad(lat)
        lng_rad = deg2rad(lng)

        x = :math.cos(lat_rad) * :math.cos(lng_rad)
        y = :math.cos(lat_rad) * :math.sin(lng_rad)
        z = :math.sin(lat_rad)

        {x_acc + x, y_acc + y, z_acc + z}
      end)

    x_avg = x / count
    y_avg = y / count
    z_avg = z / count

    hyp = :math.sqrt(x_avg * x_avg + y_avg * y_avg)
    lat = rad2deg(:math.atan2(z_avg, hyp))
    lng = rad2deg(:math.atan2(y_avg, x_avg))

    {lat, lng}
  end
end
