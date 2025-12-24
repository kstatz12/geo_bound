defmodule Geo.Data do
  @moduledoc """
    loads data from file
  """

  def load!(path) do
    case Path.extname(path) do
      ".tgz" ->
        with {:ok, handle} <- :zip.zip_open(path),
             {:ok, [entry]} <- :zip.zip_get(handle),
             content <- File.read!(entry) do
          content
        else
          _ -> nil
        end

      ".json" ->
        File.read!(path)

      _ ->
        raise ArgumentError, "Unsupported file extension: #{Path.extname(path)}"
    end
  end

  def parse!(raw),
    do:
      raw
      |> Poison.decode!(keys: :atoms)
end
