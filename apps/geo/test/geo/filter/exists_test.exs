defmodule Geo.Filter.ExistsTest do
  use ExUnit.Case, async: true

  alias Geo.{Queries}
  alias Geo.Servers.{QueryServer}

  alias Geo.Filter.Exists

  test "city in state has results" do
    assert {:ok, _} =
             Queries.city_in_state("IL", "chicago") |> QueryServer.query() |> Exists.exists()
  end

  test "city in state has no results" do
    assert {:error, :no_results} =
             Queries.city_in_state("OZ", "land of") |> QueryServer.query() |> Exists.exists()
  end

  test "postal code in state exists" do
    assert {:ok, _} =
             Queries.postal_code_in_state("IL", "60137") |> QueryServer.query() |> Exists.exists()
  end

  test "postal code in state does not exist" do
    assert {:error, :no_results} =
             Queries.postal_code_in_state("OZ", "11111") |> QueryServer.query() |> Exists.exists()
  end

  test "postal code in city exists" do
    assert {:ok, _} =
             Queries.postal_code_in_city("chicago", "60601")
             |> QueryServer.query()
             |> Exists.exists()
  end

  test "postal code in city does not exist" do
    assert {:error, :no_results} =
             Queries.postal_code_in_city("land of oz", "11111")
             |> QueryServer.query()
             |> Exists.exists()
  end
end
