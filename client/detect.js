//require('./dom');
var Detect = {};

Detect.supportsWebSocket = function() {
    var out = window.WebSocket || window.MozWebSocket;
    if (!out) console.log('NO WEBSOCKETS!!!');
    return out;
};

Detect.userAgentContains = function(string) {
    return window.navigator.userAgent.indexOf(string) != -1;
};

Detect.isTablet = function(screenWidth) {
    if(screenWidth > 640) {
        if((Detect.userAgentContains('Android') && Detect.userAgentContains('Firefox'))
        || Detect.userAgentContains('Mobile')) {
            return true;
        }
    }
    return false;
};

Detect.isWindows = function() {
    return Detect.userAgentContains('Windows');
}

Detect.isChromeOnWindows = function() {
    return Detect.userAgentContains('Chrome') && Detect.userAgentContains('Windows');
};

Detect.canPlayMP3 = function() {
    return Modernizr.audio.mp3;
};

Detect.isSafari = function() {
    return Detect.userAgentContains('Safari') && !Detect.userAgentContains('Chrome');
};

Detect.isOpera = function() {
    return Detect.userAgentContains('Opera');
};

Detect.isFirefoxAndroid = function() {
    return Detect.userAgentContains('Android') && Detect.userAgentContains('Firefox');
};

module.exports = Detect;
