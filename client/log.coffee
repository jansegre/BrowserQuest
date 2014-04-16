#printStackTrace = require("stacktrace-js")
{log_level} = require("./config")

#TODO: improve logging maybe?
# See this: http://stackoverflow.com/questions/9559725/extending-console-log-without-affecting-log-line
log = {}

switch log_level
  when "debug"
    log.info = console.info.bind(console, "INFO")
    log.debug = console.log.bind(console, "DEBUG")
  when "info"
    log.info = console.info.bind(console, "INFO")
    log.debug = -> null
  when "error"
    log.info = -> null
    log.debug = -> null

log.error = (message, show_tacktrace=false) ->
  console.error message
  if show_stacktrace
    trace = printStackTrace()
    console.error trace.join("\n\n")
    console.error "-----------------------------"

module.exports = log
