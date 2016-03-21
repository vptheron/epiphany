defmodule Epiphany.Mixfile do
  use Mix.Project

  def project do
    [
     app: :epiphany,
     version: "0.1.0-dev",
     elixir: "~> 1.2",
     name: "Epiphany",
     description: "Cassandra driver for Elixir.",
     source_url: "https://github.com/vptheron/epiphany",
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test,
                         "coveralls.detail": :test,
                         "coveralls.post": :test],
     docs: [extras: ["README.md"]]
    ]
  end

  def application do
    [applications: [:logger, :connection]]
  end

  defp deps do
    [
      {:connection, "~> 1.0"},
      {:excheck, "~> 0.3", only: :test},
      {:triq, github: "krestenkrab/triq", only: :test},
      {:excoveralls, "~> 0.4", only: :test},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
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
