var Player = require('./player');
var Types = require('./types');

var Warrior = Player.extend({
    init: function(id, name) {
        this._super(id, name, Types.Entities.WARRIOR);
    },
});

module.exports = Warrior;
