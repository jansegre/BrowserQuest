should = require("should")
{LootException} = require("../exceptions")

describe "Exception", ->
  beforeEach (done) =>
    @message = "Loot Exception"
    @loot_exception = new LootException(@message)
    done()

  describe "#init", =>
    it "sets message to be the passed value", =>
      @loot_exception.message.should.equal @message
