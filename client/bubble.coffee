_ = require("underscore")
$ = require("jquery")
Timer = require("./timer")

class Bubble
  constructor: (@id, @element, time) ->
    @timer = new Timer(5000, time)

  isOver: (time) ->
    return true  if @timer.isOver(time)
    false

  destroy: ->
    $(@element).remove()

  reset: (time) ->
    @timer.lastTime = time

class BubbleManager
  constructor: (@container) ->
    @bubbles = {}

  getBubbleById: (id) ->
    return @bubbles[id]  if id of @bubbles
    null

  create: (id, message, time) ->
    if @bubbles[id]
      @bubbles[id].reset time
      $("#" + id + " p").html message
    else
      el = $("<div id=\"#{id}\" class=\"bubble\"><p>#{message}</p><div class=\"thingy\"></div></div>")
      $(el).appendTo @container
      @bubbles[id] = new Bubble(id, el, time)

  update: (time) ->
    bubblesToDelete = []
    _.each @bubbles, (bubble) ->
      if bubble.isOver(time)
        bubble.destroy()
        bubblesToDelete.push bubble.id

    _.each bubblesToDelete, (id) =>
      delete @bubbles[id]

  clean: ->
    bubblesToDelete = []
    _.each @bubbles, (bubble) ->
      bubble.destroy()
      bubblesToDelete.push bubble.id

    _.each bubblesToDelete, (id) =>
      delete @bubbles[id]

    @bubbles = {}

  destroyBubble: (id) ->
    bubble = @getBubbleById(id)
    if bubble
      bubble.destroy()
      delete @bubbles[id]

  forEachBubble: (callback) ->
    _.each @bubbles, (bubble) ->
      callback bubble

module.exports = BubbleManager
