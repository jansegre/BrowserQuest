_ = require("underscore")
fs = require("fs")
yaml = require("js-yaml")

config = yaml.safeLoad(fs.readFileSync("#{__dirname}/../config/client.yaml", "utf8"))

_.defaults(config,
  host: "localhost"
  port: 8000
  dispatcher: false
)

module.exports = config
