###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

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
