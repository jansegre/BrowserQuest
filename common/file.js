/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

var exists, existsSync;
(function () {
    var semver = require('semver');
    var module = (semver.satisfies(process.version, '>=0.7.1') ? require('fs') : require('path'));

    exists = module.exists;
    existsSync = module.existsSync;
})();

if (!(typeof exports === 'undefined')) {
    module.exports.exists = exists;
    module.exports.existsSync = existsSync;
}
