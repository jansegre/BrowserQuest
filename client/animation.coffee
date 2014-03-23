class Animation
  constructor: (name, length, row, width, height) ->
    @name = name
    @length = length
    @row = row
    @width = width
    @height = height
    @reset()

  tick: ->
    i = @currentFrame.index
    i = (if (i < @length - 1) then i + 1 else 0)
    if @count > 0
      if i is 0
        @count -= 1
        if @count is 0
          @currentFrame.index = 0
          @endcount_callback()
          return
    @currentFrame.x = @width * i
    @currentFrame.y = @height * @row
    @currentFrame.index = i

  setSpeed: (speed) ->
    @speed = speed

  setCount: (count, onEndCount) ->
    @count = count
    @endcount_callback = onEndCount

  isTimeToAnimate: (time) ->
    (time - @lastTime) > @speed

  update: (time) ->
    @lastTime = time  if @lastTime is 0 and @name.substr(0, 3) is "atk"
    if @isTimeToAnimate(time)
      @lastTime = time
      @tick()
      true
    else
      false

  reset: ->
    @lastTime = 0
    @currentFrame =
      index: 0
      x: 0
      y: @row * @height

module.exports = Animation
