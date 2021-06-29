defmodule UeberauthExact.MixProject do
  use Mix.Project

  @source_url "https://github.com/wearethefoos/ueberauth_exact"
  @version "0.1.1"

  def project do
    [
      app: :ueberauth_exact,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ueberauth, :oauth2]
    ]
  end

  defp deps do
    [
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:ueberauth, "~> 0.6.0"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description: "An Ueberauth strategy for using Exact Online to authenticate your users.",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Wouter de Vos"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/ueberauth_exact/changelog.html",
        GitHub: @source_url
      }
    ]
  end
end
