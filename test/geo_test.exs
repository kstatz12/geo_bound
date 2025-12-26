defmodule GeoTest do
  use ExUnit.Case
  doctest Geo

  test "greets the world" do
    assert Geo.hello() == :world
  end
end
