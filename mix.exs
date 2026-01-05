defmodule ProcesadorArchivos.MixProject do
  use Mix.Project

  def project do
    [
      app: :procesador_archivos,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # JSON parsing (required for Delivery 1)
      {:jason, "~> 1.4"},
      {:nimble_csv, "~> 1.2", optional: true},
      {:benchee, "~> 1.0", only: :test, optional: true}
    ]
  end
end
