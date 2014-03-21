var should = require('should');
var Exceptions = require('../exceptions');

describe('LootException', function() {
    var self = this;

    beforeEach(function(done) {
        self.message = "Loot Exception";
        self.loot_exception = new Exceptions.LootException(self.message);
        done();
    });

    describe('#init', function() {
        it('sets message to be the passed value', function() {
            self.loot_exception.message.should.equal(self.message);
        });
    });
});
