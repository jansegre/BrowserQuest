var sha1 = require('sha1');
var Class = require('class.extend');
var Util = require('./util');

var EntryPoint = Class.extend({
        init: function(){
            //"hashedID" ← use tools/sha1_encode.html to generate: function(){} ← action
            this.hashes = {
                "Obda3tBpL9VXsXsSsv5xB4QKNo4=": function(aGame){
                    aGame.player.switchArmor(aGame.sprites["firefox"]);
                    aGame.showNotification("You enter the game as a fox, but not invincible…");
                }
            };
        },

        execute: function(game){
            var res = false;
            var ID = Util.getUrlVars()["entrance"];
            if(ID!=undefined){
                var hash = sha1(ID);
                if(this.hashes[hash]==undefined){
                    game.showNotification("Nice try little scoundrel… bad code, though");
                }
                else{
                    this.hashes[hash](game);
                    res = true;
                }
            }
            return res;
        }
});

module.exports = EntryPoint;
