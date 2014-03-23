printStackTrace = require("stacktrace-js")
#TODO: make proper class
#TODO: find out how to point to where the log was called, as in console.log

Logger = (level) ->
  @level = level
  return

Logger::info = ->

Logger::debug = ->

Logger::error = ->


#>>excludeStart("prodHost", pragmas.prodHost);
Logger::info = (message) ->
  console.info message  if console  if @level is "debug" or @level is "info"
  return

Logger::debug = (message) ->
  console.log message  if console  if @level is "debug"
  return

Logger::error = (message, stacktrace) ->
  if console
    console.error message
    if stacktrace
      trace = printStackTrace()
      console.error trace.join("\n\n")
      console.error "-----------------------------"
  return
#>>excludeEnd("prodHost");

log = new Logger("debug")
module.exports = log
