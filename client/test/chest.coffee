should = require("should")
sinon = require("sinon")
Chest = require("../chest")

describe "Chest", ->
  beforeEach (done) =>
    @chest = new Chest(1)
    done()

  describe "#getSpriteName", =>
    it "should return \"chest\"", =>
      @chest.getSpriteName().should.equal "chest"

  describe "#isMoving", =>
    it "should return false", =>
      @chest.isMoving().should.be.false

  describe "#onOpen", =>
    it "sets open_callback to the passed function", =>
      func = ->
      @chest.onOpen func
      @chest.open_callback.toString().should.equal func.toString()

  describe "#open", =>
    it "calls open_callback if set", =>
      spy = sinon.spy()
      @chest.onOpen spy
      @chest.open()
      spy.called.should.equal.true

    it "does not call open_callback if not set", =>
      spy = sinon.spy(@chest.open_callback)
      @chest.open()
      spy.called.should.equal.false
