defmodule Geo.Filter.RadiusTest do
  use ExUnit.Case, async: false

  alias Geo.{Queries}
  alias Geo.Servers.{QueryServer}

  alias Geo.Filter.Radius

  setup do
    []
  end

  test "postal code near" do
    assert [] != Queries.all() |> QueryServer.query() |> Radius.postal_code("60137", 10)
  end

  test "partial postal code near" do
    assert [] != Queries.all() |> QueryServer.query() |> Radius.postal_code("601", 10)
  end

  test "near city name" do
    assert [] != Queries.all() |> QueryServer.query() |> Radius.city("glen ellyn", "IL", 100)
  end

  test "no zip" do
    assert {:error, _} = Queries.all() |> QueryServer.query() |> Radius.postal_code("11111", 10)
  end

  test "no city" do
    assert [] == Queries.all() |> QueryServer.query() |> Radius.city("rome", "ZQ", 100)
  end

  test "non-freedom units test" do
    assert [] !=
             Queries.all()
             |> QueryServer.query()
             |> Radius.radius_filter(41.9008, -87.6528, 10, :km)
  end

  test "non existing postal code" do
    assert {:error, _} = Queries.all() |> QueryServer.query() |> Radius.postal_code("11111", 10)
  end

  test "non existing partial postal code" do
    assert {:error, _} = Queries.all() |> QueryServer.query() |> Radius.postal_code("000", 10)
  end

  test "too short postal code" do
    assert {:error, _} = Queries.all() |> QueryServer.query() |> Radius.postal_code("60", 10)
  end
end
