###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

Util = {}
Util.bind = (fun, bind) ->
  ->
    args = Array::slice.call(arguments)
    fun.apply bind or null, args

Util.isInt = (n) ->
  (n % 1) is 0

Util.TRANSITIONEND = "transitionend webkitTransitionEnd oTransitionEnd"

# http://paulirish.com/2011/requestanimationframe-for-smart-animating/
#Util.requestAnimFrame = (->
#  #FIXME?
#  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback, element) ->
## DOMElement
#    window.setTimeout callback, 1000 / 60
#    return
#)()

#TODO: find out why is this not working
Util.requestAnimFrame =
  window.requestAnimationFrame or
  window.webkitRequestAnimationFrame or
  window.mozRequestAnimationFrame or
  window.oRequestAnimationFrame or
  window.msRequestAnimationFrame or
  (callback, element) ->
    window.setTimeout callback, 1000 / 60

Util.getUrlVars = ->
  #from http://snipplr.com/view/19838/get-url-parameters/
  vars = {}
  parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/g, (m, key, value) ->
    vars[key] = value
    return
  )
  vars

module.exports = Util
