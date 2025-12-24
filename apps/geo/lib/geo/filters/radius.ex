defmodule Geo.Filter.Radius do
  @moduledoc """
  radius based geo filters
  """

  alias Geo.Math.{Haversine, GeoCenter}
  alias Geo.Servers.QueryServer
  alias Geo.{Queries, StringFilter}

  def postal_code(results, postal_code, max_distance \\ 10) do
    resolve_to_location(postal_code)
    |> case do
      {:ok, {lat, lng}} -> results |> radius_filter(lat, lng, max_distance)
      {:error, reason} -> {:error, reason}
    end
  end

  def city(results, city_name, state_code, max_distance \\ 10) do
    Queries.city_data(city_name, state_code)
    |> QueryServer.query()
    |> case do
      [] ->
        []

      records ->
        with {lat, lng} <- List.first(records) do
          radius_filter(results, lat, lng, max_distance)
        else
          _ ->
            []
        end
    end
  end

  def resolve_to_location(postal_code) when byte_size(postal_code) == 3 do
    Queries.postal_codes_data()
    |> QueryServer.query()
    |> StringFilter.filter(postal_code, :begins_with, fn {p, _, _} -> p end)
    |> Enum.map(fn {_, lat, lng} -> {lat, lng} end)
    |> case do
      [] -> {:error, "invalid postal code"}
      coords -> {:ok, GeoCenter.center(coords)}
    end
  end

  def resolve_to_location(postal_code) when byte_size(postal_code) == 5 do
    Queries.postal_code_data(postal_code)
    |> QueryServer.query()
    |> case do
      [] -> {:error, "invalid postal code"}
      [coords] -> {:ok, coords}
    end
  end

  def resolve_to_location(_), do: {:error, "invalid postal code"}

  def radius_filter(records, lat, lng, max_distance, unit \\ :miles) do
    records
    |> Enum.group_by(fn {_id, rec} -> rec.city_name end)
    |> Enum.map(fn {city_name, city_entries} ->
      [first_entry | _rest] = city_entries
      {_id, rec} = first_entry


      city_distance =
        Haversine.distance_miles(
          lat,
          lng,
          rec.city_latitude,
          rec.city_longitude
        )

      filtered_postal_codes =
        city_entries
        |> Enum.map(fn {_id, rec} ->
          %{
            postal_code: rec.postal_code,
            latitude: rec.latitude,
            longitude: rec.longitude,
            distance: calculate_distance(lat, lng, rec.latitude, rec.longitude, unit)
          }
        end)
        |> Enum.filter(fn postal_code -> postal_code.distance <= max_distance end)

      {
        city_name,
        %{
          city_name: city_name,
          state_code: rec.state_code,
          latitude: rec.city_latitude,
          longitude: rec.city_longitude,
          distance: city_distance,
          postal_codes: filtered_postal_codes
        }
      }
    end)
    # Filter cities within max_distance and that have at least one postal code
    |> Enum.filter(fn {_city_name, city_data} ->
      city_data.distance <= max_distance and length(city_data.postal_codes) > 0
    end)
    |> Enum.into(%{})
  end

  defp calculate_distance(lat1, lon1, lat2, lon2, unit) do
    case unit do
      :km -> Haversine.distance_km(lat1, lon2, lat2, lon2)
      :miles -> Haversine.distance_miles(lat1, lon1, lat2, lon2)
    end
  end
end
