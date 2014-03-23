class Timer
  constructor: (@duration, startTime) ->
    @lastTime = startTime or 0

  isOver: (time) ->
    over = false
    if (time - @lastTime) > @duration
      over = true
      @lastTime = time
    over

module.exports = Timer
