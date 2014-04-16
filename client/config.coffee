###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

_ = require("underscore")
fs = require("fs")
yaml = require("js-yaml")

config = yaml.safeLoad(fs.readFileSync("#{__dirname}/../config/client.yaml", "utf8"))

_.defaults(config,
  host: "localhost"
  port: 8000
  dispatcher: false
  log_level: "error"
)

module.exports = config
