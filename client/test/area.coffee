should = require("should")
Area = require("../area")

describe "Area", ->
  beforeEach (done) =>
    @x = 0
    @y = 0
    @width = 10
    @height = 10
    @area = new Area(@x, @y, @width, @height)
    done()

  describe ".init", =>
    it "sets x to be the passed value", =>
      @area.x.should.equal @x

    it "sets y to be the passed value", =>
      @area.y.should.equal @y

    it "sets width to be the passed value", =>
      @area.width.should.equal @width

    it "sets height to be the passed value", =>
      @area.height.should.equal @height

  describe "#contains", =>
    it "returns true if the given entity is within the given coordinates", =>
      entity = gridX: 2, gridY: 2
      @area.contains(entity).should.be.true

    it "returns false if the given entity is not within the given coordinates", =>
      entity = gridX: 20, gridY: 20
      @area.contains(entity).should.be.false