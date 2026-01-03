defmodule Geo.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Geo.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, ">= 0.0.0"},
      {:ex2ms, "~> 1.0"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      # test
      {:excoveralls, "~> 0.7", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
