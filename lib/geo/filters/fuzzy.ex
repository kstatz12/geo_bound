defmodule Geo.Filter.Fuzzy do
  @moduledoc """
  fuzzy matching for expanding locations
  """
  alias Geo.Filter.StringFilter

  def starts_with(results, term, selector \\ fn x -> x end) do
    results |> StringFilter.filter(term, :begins_with, selector)
  end

  def ends_with(results, term, selector \\ fn x -> x end) do
    results |> StringFilter.filter(term, :ends_with, selector)
  end

  def contains(results, term, selector \\ fn x -> x end) do
    results |> StringFilter.filter(term, :contains, selector)
  end

  def not_starts_with(results, term, selector \\ fn x -> x end) do
    results |> StringFilter.reject(term, :begins_with, selector)
  end

  def not_ends_with(results, term, selector \\ fn x -> x end) do
    results |> StringFilter.reject(term, :ends_with, selector)
  end

  def not_contains(results, term, selector \\ fn x -> x end) do
    results |> StringFilter.reject(term, :contains, selector)
  end
end
