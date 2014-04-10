should = require("should")
sinon = require("sinon")
Item = require("../../client/item")
Types = require("../../common/types")

describe "Item", ->
  beforeEach (done) =>
    @item = new Item(1, "testKind", "type")
    done()

  before =>
    stub = sinon.stub(Types, "getKindAsString")
    stub.withArgs("testKind").returns "testKind"

  describe ".init", =>
    it "sets itemKind to the passed kind", =>
      @item.itemKind.should.equal "testKind"

    it "sets type to the passed type", =>
      @item.type.should.equal "type"

    it "sets wasDropped to false", =>
      @item.wasDropped.should.equal.false

  describe "#hasShadow", =>
    it "should return true", =>
      @item.hasShadow().should.be.true

  describe "#onLoot", =>
    player = undefined
    spy = undefined

    beforeEach =>
      player = sinon.stub()
      spy = sinon.spy()

    it "calls switchWeapon on passed player if type equals weapon", =>
      player.switchWeapon = spy
      @item.type = "weapon"
      @item.onLoot player
      spy.calledWith("testKind").should.be.true

    it "calls armorloot_callback on passed player if type equals armor", =>
      player.armorloot_callback = spy
      @item.type = "armor"
      @item.onLoot player
      spy.calledWith("testKind").should.be.true

  describe "#getSpriteName", =>
    it "should return 'item-' plus itemKind", =>
      @item.getSpriteName().should.equal "item-testKind"

  describe "#getLootMessage", =>
    it "should return lootMessage", =>
      @item.lootMessage = "Loot message"
      @item.getLootMessage().should.equal "Loot message"
