defmodule EnochEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :enoch_ex,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {EnochEx.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:astro, "~> 0.4.0"},
      {:timex, "~> 3.7"},
      {:ip2location, github: "nazipov/ip2location-elixir"},
      #{:wheretz, "~> 0.1.16"},
      {:wheretz, github: "niccolox/wheretz"},
      {:quantum, "~> 2.4"}
    ]
  end
end
