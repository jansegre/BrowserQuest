###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

#XXX: not browserifiable, may not be a big deal
path = require("path")

databaseselector = (config) ->
  require path.resolve(__dirname, "db_providers", config.database)

module.exports = databaseselector
