config =
  dev:
    host: "localhost"
    port: 8000
    dispatcher: false

  build: require("./config/config_build")

# Exception triggered when config_local.json does not exist. Nothing to do here.
try
  config.local = require("./config/config_local")

module.exports = config
