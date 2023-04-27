# Utils

**TODO: Add description**

## Runtime config

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `utils` to your list of dependencies in `mix.exs`:

```elixir
import Config

import ConfigUtils, only: [get_env!: 3, get_env!: 2]

{:ok, in_container} = in_container!()

if in_container do
  config :logger,
    handle_otp_reports: true,
    backends: [
      :console
    ]

  config :logger,
         :console,
         level: get_env!("CONSOLE_LOG_LEVEL"), :atom, :info),
         format: get_env!("LOG_FORMAT"), :string, "[$date] [$time] [$level] [$node] [$metadata] [$levelpad] [$message]\n"),
         metadata: :all
else
  config :logger,
    handle_otp_reports: true,
    backends: [
      :console,
      {LoggerFileBackend, :info_log},
      {LoggerFileBackend, :error_log}
    ]

  config :logger,
         :console,
         level: get_env!("CONSOLE_LOG_LEVEL"), :atom, :info),
         format: get_env!("LOG_FORMAT"), :string, "[$date] [$time] [$level] [$node] [$metadata] [$levelpad] [$message]\n"),
         metadata: :all

  config :logger,
         :info_log,
         level: :info,
         path: get_env!("LOG_PATH"), :string, "log") <> "/#{Node.self()}/info.log",
         format: get_env!("LOG_FORMAT"), :string, "[$date] [$time] [$level] [$node] [$metadata] [$levelpad] [$message]\n"),
         metadata: :all

  config :logger,
         :error_log,
         level: :error,
         path: get_env!("LOG_PATH"), :string, "log") <> "/#{Node.self()}/error.log",
         format: get_env!("LOG_FORMAT"), :string, "[$date] [$time] [$level] [$node] [$metadata] [$levelpad] [$message]\n"),
         metadata: :all
end

if config_env() in [:dev] do
end

if config_env() in [:prod] do
end

```

