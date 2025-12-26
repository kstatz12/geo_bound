defmodule Geo.Filter.Exists do
  @moduledoc """
  filter to respond uniformly to queries to see if any results returned
  """

  def exists([]) do
    {:error, :no_results}
  end

  def exists(r) do
    {:ok, r}
  end
end
