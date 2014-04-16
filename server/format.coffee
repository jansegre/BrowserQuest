###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

_ = require("underscore")
Types = require("../common/types")

#TODO: find out why this is encapsulated, otherwise normalize it
(->
  class FormatChecker
    constructor: ->
      @formats = []
      @formats[Types.Messages.CREATE] = [
        "s"
        "s"
        "s"
      ]
      @formats[Types.Messages.LOGIN] = [
        "s"
        "s"
      ]
      @formats[Types.Messages.MOVE] = [
        "n"
        "n"
      ]
      @formats[Types.Messages.LOOTMOVE] = [
        "n"
        "n"
        "n"
      ]
      @formats[Types.Messages.AGGRO] = ["n"]
      @formats[Types.Messages.ATTACK] = ["n"]
      @formats[Types.Messages.HIT] = ["n"]
      @formats[Types.Messages.HURT] = ["n"]
      @formats[Types.Messages.CHAT] = ["s"]
      @formats[Types.Messages.LOOT] = ["n"]
      @formats[Types.Messages.TELEPORT] = [
        "n"
        "n"
      ]
      @formats[Types.Messages.ZONE] = []
      @formats[Types.Messages.OPEN] = ["n"]
      @formats[Types.Messages.CHECK] = ["n"]
      @formats[Types.Messages.ACHIEVEMENT] = [
        "n"
        "s"
      ]

    check: (msg) ->
      message = msg.slice(0)
      type = message[0]
      format = @formats[type]
      message.shift()
      if format
        return false  if message.length isnt format.length
        i = 0
        n = message.length

        while i < n
          return false  if format[i] is "n" and not _.isNumber(message[i])
          return false  if format[i] is "s" and not _.isString(message[i])
          i += 1
        true
      else if type is Types.Messages.WHO

        # WHO messages have a variable amount of params, all of which must be numbers.
        message.length > 0 and _.all(message, (param) ->
          _.isNumber param
        )
      else if type is Types.Messages.LOGIN

        # LOGIN with or without guild
        _.isString(message[0]) and _.isNumber(message[1]) and _.isNumber(message[2]) and (message.length is 3 or (_.isNumber(message[3]) and _.isString(message[4]) and message.length is 5))
      else if type is Types.Messages.GUILD
        if message[0] is Types.Messages.GUILDACTION.CREATE
          message.length is 2 and _.isString(message[1])
        else if message[0] is Types.Messages.GUILDACTION.INVITE
          message.length is 2 and _.isString(message[1])
        else if message[0] is Types.Messages.GUILDACTION.JOIN
          message.length is 3 and _.isNumber(message[1]) and _.isBoolean(message[2])
        else if message[0] is Types.Messages.GUILDACTION.LEAVE
          message.length is 1
        else if message[0] is Types.Messages.GUILDACTION.TALK
          message.length is 2 and _.isString(message[1])
        else
          log.error "Unknown message type: " + type
          false
      else
        log.error "Unknown message type: " + type
        false

  checker = new FormatChecker()
  exports.check = checker.check.bind(checker)
)()
