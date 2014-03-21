var Class = require('class.extend');

var Exceptions = {

    LootException: Class.extend({
        init: function(message) {
            this.message = message;
        }
    })
};

module.exports = Exceptions;
