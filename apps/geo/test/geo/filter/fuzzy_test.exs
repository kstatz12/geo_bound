defmodule Geo.Filter.FuzzyTest do
  use ExUnit.Case, async: true

  alias Geo.{Queries}
  alias Geo.Servers.QueryServer

  alias Geo.Filter.{Fuzzy, Exists}

  test "starts with" do
    assert [] !=
             Queries.all()
             |> QueryServer.query()
             |> Fuzzy.starts_with("606", fn {_, result} -> result.postal_code end)
  end

  test "ends with" do
    assert [] !=
             Queries.all()
             |> QueryServer.query()
             |> Fuzzy.ends_with("go", fn {_, result} -> result.city_name end)
  end

  test "contains" do
    assert [] !=
             Queries.all()
             |> QueryServer.query()
             |> Fuzzy.contains("chi", fn {_, result} -> result.city_name end)
  end

  test "not starts with" do
    assert [] !=
             Queries.all()
             |> QueryServer.query()
             |> Fuzzy.not_starts_with("601", fn {_, result} -> result.postal_code end)
  end

  test "not contains" do
    assert [] !=
             Queries.all()
             |> QueryServer.query()
             |> Fuzzy.not_contains("chi", fn {_, result} -> result.city_name end)
  end

  test "not ends with" do
    assert [] !=
             Queries.all()
             |> QueryServer.query()
             |> Fuzzy.not_ends_with("137", fn {_, result} -> result.postal_code end)
  end

  test "states fuzzy query" do
    assert {:ok, _} =
             Queries.states() |> QueryServer.query() |> Fuzzy.contains("IL") |> Exists.exists()
  end

  test "cities fuzzy query" do
    assert {:ok, _} =
             Queries.cities() |> QueryServer.query() |> Fuzzy.contains("hic") |> Exists.exists()
  end

  test "postal codes fuzzy query" do
    assert {:ok, _} =
             Queries.postal_codes()
             |> QueryServer.query()
             |> Fuzzy.contains("013")
             |> Exists.exists()
  end
end
