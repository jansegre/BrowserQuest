#XXX: not browserifiable
path = require("path")
module.exports = (config) ->
  require path.resolve(__dirname, "db_providers", config.database)
