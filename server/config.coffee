###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

_ = require("underscore")
fs = require("fs")
yaml = require("js-yaml")

config = yaml.safeLoad(fs.readFileSync("#{__dirname}/../config/server.yaml", "utf8"))

_.defaults(config,
  port: 8000
  debug_level: "info"
  nb_players_per_world: 200
  nb_worlds: 5
  map_filepath: "./server/maps/world_server.json"
  metrics_enabled: false
  use_one_port: true
  redis_port: 6379
  redis_host: "127.0.0.1"
  memcached_host: "127.0.0.1"
  memcached_port: 11211
  game_servers: [{"server": "localhost", "name": "localhost"}]
  server_name : "localhost"
  production: "heroku"
  database: "redis"
)

module.exports = config
