defmodule Epiphany.Mixfile do
  use Mix.Project

  def project do
    [app: :epiphany,
     version: "0.1.0-dev",
     elixir: "~> 1.2",
     name: "Epiphany",
     description: "Cassandra driver for Elixir.",
     source_url: "https://github.com/vptheron/epiphany",
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :connection]]
  end

  defp deps do
    [
      {:connection, "~> 1.0"}
    ]
  end

  defp package do
    [
      maintainers: ["Vincent Theron"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/vptheron/epiphany"}
    ]
  end
end
