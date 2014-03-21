//require('./dom');

var Util = {};

Util.bind = function (fun, bind) {
    return function () {
        var args = Array.prototype.slice.call(arguments);
        return fun.apply(bind || null, args);
    };
};

Util.isInt = function(n) {
    return (n % 1) === 0;
};

Util.TRANSITIONEND = 'transitionend webkitTransitionEnd oTransitionEnd';

// http://paulirish.com/2011/requestanimationframe-for-smart-animating/
Util.requestAnimFrame = (function(){
    //FIXME?
   return  window.requestAnimationFrame       ||
            window.webkitRequestAnimationFrame ||
            window.mozRequestAnimationFrame    ||
            window.oRequestAnimationFrame      ||
            window.msRequestAnimationFrame     ||
            function(/* function */ callback, /* DOMElement */ element){
                window.setTimeout(callback, 1000 / 60);
            };
})();

Util.getUrlVars = function() {
    //from http://snipplr.com/view/19838/get-url-parameters/
    var vars = {};
    var parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
        vars[key] = value;
    });
    return vars;
}

module.exports = Util;
