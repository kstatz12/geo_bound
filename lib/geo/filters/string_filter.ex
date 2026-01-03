defmodule Geo.Filter.StringFilter do
  @moduledoc """
  Provides a function to filter strings based on a multi-word query using
  one of the following operations:


  - `:begins_with`  → each word in query must prefix a corresponding word in the target
    - `:ends_with`    → each word in query must suffix a corresponding word in the target
    - `:contains`     → each word in query must be a substring of the corresponding word in the target

  The comparison is case-insensitive and word-order-sensitive.
  """

  def filter(results, terms, operation_type) do
    words = split(terms)
    Enum.filter(results, fn r -> match_prefixes(words, split(r), operation_type) end)
  end

  def filter(results, terms, operation_type, selector) do
    words = split(terms)
    Enum.filter(results, fn r -> match_prefixes(words, split(selector.(r)), operation_type) end)
  end

  def reject(results, terms, operation_type, selector) do
    words = split(terms)
    Enum.reject(results, fn r -> match_prefixes(words, split(selector.(r)), operation_type) end)
  end


  # if we made it all the way through with no misses, true
  def match_prefixes([], [], _), do: true
  # if we exhausted the search terms, but there are still elements
  # in the target string true
  def match_prefixes([], _, _), do: true
  # if we still have search terms but the target string
  # has been exhauxted its not a match
  def match_prefixes(_, [], _), do: false
  # null handling match
  def match_prefixes(_, nil, _), do: false

  def match_prefixes([sh | st], [th | tt], operation_type) do
    if matches?(sh, th, operation_type) do
      match_prefixes(st, tt, operation_type)
    else
      false
    end
  end

  def matches?(source, target, operation_type) do
    case operation_type do
      :contains -> String.contains?(target, source)
      :begins_with -> String.starts_with?(target, source)
      :ends_with -> String.ends_with?(target, source)
    end
  end

  def split(nil), do: nil

  def split(str) do
    str
    |> String.trim()
    |> String.split(" ")
  end
end
