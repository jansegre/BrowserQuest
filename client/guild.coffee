###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

class Guild
  constructor: (@id, @name) ->
    @members = [] #name

#, Maybe useful later… see TODO: updateguild
#
#    addMembers: function(membersList) {
#        //maybe we could have tested the form of the array…
#        this.members = _.union(this.members, membersList);
#    },
#
#    removeMembers: function(membersList) {
#        this.members = _.difference(this.members, membersList);
#    },
#
#    listMembers: function(iterator) {
#        return _.filter(this.members, iterator);
#    }

module.exports = Guild
