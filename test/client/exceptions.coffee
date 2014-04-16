###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

should = require("should")
{LootException} = require("../../client/exceptions")

describe "Exception", ->
  beforeEach (done) =>
    @message = "Loot Exception"
    @loot_exception = new LootException(@message)
    done()

  describe "#init", =>
    it "sets message to be the passed value", =>
      @loot_exception.message.should.equal @message
