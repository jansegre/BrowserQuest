#XXX: not browserifiable, may not be a big deal
path = require("path")

databaseselector = (config) ->
  require path.resolve(__dirname, "db_providers", config.database)

module.exports = databaseselector
