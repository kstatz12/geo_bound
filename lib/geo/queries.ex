defmodule Geo.Queries do
  @moduledoc """
  queries for geonames
  """

  import Ex2ms

  # lookup queries

  def all do
    fun do
      location -> location
    end
  end

  def states do
    fun do
      {_id, %{state_code: value}} -> value
    end
  end

  def cities do
    fun do
      {_id, %{city_name: value}} -> value
    end
  end

  def postal_codes do
    fun do
      {_id, %{postal_code: value}} -> value
    end
  end

  def postal_codes_data do
    fun do
      {_id, %{postal_code: postal_code, latitude: latitude, longitude: longitude}} ->
        {
          postal_code,
          latitude,
          longitude
        }
    end
  end

  def postal_codes_for_state(state_code) do
    fun do
      {_id, %{postal_code: pc, state_code: ^state_code}} -> pc
    end
  end

  def postal_codes_for_city(city_name, state_code) do
    fun do
      {_id, %{city_name: ^city_name, state_code: ^state_code, latitude: lat, longitude: lng}} ->
        {lat, lng}
    end
  end

  def postal_code_data(postal_code) do
    fun do
      {_id, %{postal_code: ^postal_code, latitude: latitude, longitude: longitude}} ->
        {
          latitude,
          longitude
        }
    end
  end

  def city_records(city_name, state_code) do
    fun do
      {_id,
       %{
         city_name: ^city_name,
         state_code: ^state_code,
         city_latitude: lat,
         city_longitude: lon,
         alt_name: an
       }} ->
        {lat, lon, an}
    end
  end

  def postal_code_records(pc) do
    fun do
      {_id, %{postal_code: ^pc, city_name: cn, state_code: sc, latitude: lat, longitude: lng}} ->
        {cn, sc, lat, lng}
    end
  end

  def city_data(city_name, state_code) do
    [
      {{:_,
        %{
          city_name: :"$2",
          city_latitude: :"$3",
          city_longitude: :"$4",
          state_code: :"$1"
        }}, [{:andalso, {:==, :"$1", state_code}, {:==, :"$2", city_name}}], [{{:"$3", :"$4"}}]}
    ]
  end

  # exists queries
  def city_in_state(state_code, city_name) do
    fun do
      {_id, %{state_code: ^state_code, city_name: ^city_name}} -> true
    end
  end

  def postal_code_in_state(state_code, postal_code) do
    fun do
      {_id, %{state_code: ^state_code, postal_code: ^postal_code}} -> true
    end
  end

  def postal_code_in_city(city_name, postal_code) do
    fun do
      {_id, %{city_name: ^city_name, postal_code: ^postal_code}} -> true
    end
  end
end
