use Mix.Config
import_config "#{Mix.env}.exs"

config :farmbot_auth,
  callbacks: [Farmbot.RPC.Transport.GenMqtt.Handler]

config :farmbot_configurator,
  callback: Farmbot.BotState.Monitor

config :json_rpc,
  transport: Farmbot.RPC.Transport.GenMqtt.Handler,
  handler:   Farmbot.RPC.Handler

config :uart,
  baud: 115200

config :logger,
  utc_logs: true

config :quantum, cron: [
  "5 1 * * *": {Farmbot.Updates.Handler, :do_update_check}
]
