defmodule Utils.MixProject do
  use Mix.Project

  def project do
    [
      app: :utils,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      # compilers: [:gettext] ++ Mix.compilers(),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # Start only this apps automatically
      # TODO: Make it application with genserver
      # applications: [],
      # A list of OTP applications your application depends on which are not included in :deps
      extra_applications: [:logger, :logger_file_backend, :runtime_tools, :crypto]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      #
      {:libcluster, "~> 3.3.1"},
      {:logger_file_backend, "~> 0.0.13"},
      #
      {:uuid, "~> 1.1.8"},
      {:inflex, "~> 2.1.0"},
      {:jason, "~> 1.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
