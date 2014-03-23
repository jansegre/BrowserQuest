Detect = {}

Detect.supportsWebSocket = ->
  out = window.WebSocket or window.MozWebSocket
  console.log "NO WEBSOCKETS!!!"  unless out
  out

Detect.userAgentContains = (string) ->
  window.navigator.userAgent.indexOf(string) isnt -1

Detect.isTablet = (screenWidth) ->
  return true  if (Detect.userAgentContains("Android") and Detect.userAgentContains("Firefox")) or Detect.userAgentContains("Mobile")  if screenWidth > 640
  false

Detect.isWindows = ->
  Detect.userAgentContains "Windows"

Detect.isChromeOnWindows = ->
  Detect.userAgentContains("Chrome") and Detect.userAgentContains("Windows")

Detect.canPlayMP3 = ->
  Modernizr.audio.mp3

Detect.isSafari = ->
  Detect.userAgentContains("Safari") and not Detect.userAgentContains("Chrome")

Detect.isOpera = ->
  Detect.userAgentContains "Opera"

Detect.isFirefoxAndroid = ->
  Detect.userAgentContains("Android") and Detect.userAgentContains("Firefox")

module.exports = Detect
