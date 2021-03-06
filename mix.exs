defmodule EmqRedisAuth.Mixfile do
  use Mix.Project

  def project do
    [app: :emq_redis_auth,
     version: "0.1.0",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases(),
    ]
  end

  defp aliases do
    [
      test: "test --no-start",
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger, :redix, :pbkdf2, :cachex],
      mod: {EmqRedisAuth, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:redix, ">= 0.0.0"},
      {:cachex, "~> 2.1"},

      {:pbkdf2,
       github: "emqtt/pbkdf2",
       only: [:test],
       ref: "2.0.1",
       manager: :make,
       optional: true,
      },

      {:emqttd,
       github: "emqtt/emqttd",
       only: [:test],
       ref: "v2.3-beta.1",
       manager: :make,
       optional: true,
      },
      # {:distillery, "~> 1.4", runtime: false},
    ]
  end
end
