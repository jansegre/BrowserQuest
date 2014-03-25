redis = require("redis")
bcrypt = require("bcrypt")
Utils = require("../utils")
Player = require("../player")
Messages = require("../message")

#TODO: there is some korean text, it shold be in english before i18n

class DatabaseHandler
  constructor: (config) ->
    @client = redis.createClient(config.redis_port, config.redis_host, socket_nodelay: true)
    @client.auth config.redis_password or ""

  loadPlayer: (player) ->
    userKey = "u:" + player.name
    curTime = new Date().getTime()
    @client.smembers "usr", (err, replies) =>
      for index in [0...replies.length]
        if replies[index].toString() is player.name
          @client.multi()
            .hget(userKey, "pw") # 0
            .hget(userKey, "armor") # 1
            .hget(userKey, "weapon") # 2
            .hget(userKey, "exp") # 3
            .hget("b:" + player.connection._connection.remoteAddress, "time") # 4
            .hget("b:" + player.connection._connection.remoteAddress, "banUseTime") # 5
            .hget("b:" + player.connection._connection.remoteAddress, "loginTime") # 6
            .hget(userKey, "avatar") # 7
            .zrange("adrank", "-1", "-1") # 8
            .get("nextNewArmor") # 9
            .hget(userKey, "inventory0") # 10
            .hget(userKey, "inventory0:number") # 11
            .hget(userKey, "inventory1") # 12
            .hget(userKey, "inventory1:number") # 13
            .hget(userKey, "achievement1:found") # 14
            .hget(userKey, "achievement1:progress") # 15
            .hget(userKey, "achievement2:found") # 16
            .hget(userKey, "achievement2:progress") # 17
            .hget(userKey, "achievement3:found") # 18
            .hget(userKey, "achievement3:progress") # 19
            .hget(userKey, "achievement4:found") # 20
            .hget(userKey, "achievement4:progress") # 21
            .hget(userKey, "achievement5:found") # 22
            .hget(userKey, "achievement5:progress") # 23
            .hget(userKey, "achievement6:found") # 24
            .hget(userKey, "achievement6:progress") # 25
            .smembers("adminname") # 26
            .zscore("adrank", player.name) # 27
            .hget(userKey, "weaponAvatar") # 28
            .hget(userKey, "x") # 29
            .hget(userKey, "y") # 30
            .hget(userKey, "achievement7:found") # 31
            .hget(userKey, "achievement7:progress") # 32
            .hget(userKey, "achievement8:found") # 33
            .hget(userKey, "achievement8:progress") # 34
            .hget("cb:" + player.connection._connection.remoteAddress, "etime") # 35
            .exec (err, replies) =>
              pw = replies[0]
              armor = replies[1]
              weapon = replies[2]
              exp = Utils.NaN2Zero(replies[3])
              bannedTime = Utils.NaN2Zero(replies[4])
              banUseTime = Utils.NaN2Zero(replies[5])
              lastLoginTime = Utils.NaN2Zero(replies[6])
              avatar = replies[7]
              pubTopName = replies[8]
              nextNewArmor = replies[9]
              inventory = [
                replies[10]
                replies[12]
              ]
              inventoryNumber = [
                Utils.NaN2Zero(replies[11])
                Utils.NaN2Zero(replies[13])
              ]
              achievementFound = [
                Utils.trueFalse(replies[14])
                Utils.trueFalse(replies[16])
                Utils.trueFalse(replies[18])
                Utils.trueFalse(replies[20])
                Utils.trueFalse(replies[22])
                Utils.trueFalse(replies[24])
                Utils.trueFalse(replies[31])
                Utils.trueFalse(replies[33])
              ]
              achievementProgress = [
                Utils.NaN2Zero(replies[15])
                Utils.NaN2Zero(replies[17])
                Utils.NaN2Zero(replies[19])
                Utils.NaN2Zero(replies[21])
                Utils.NaN2Zero(replies[23])
                Utils.NaN2Zero(replies[25])
                Utils.NaN2Zero(replies[32])
                Utils.NaN2Zero(replies[34])
              ]
              adminnames = replies[26]
              pubPoint = Utils.NaN2Zero(replies[27])
              weaponAvatar = (if replies[28] then replies[28] else weapon)
              x = Utils.NaN2Zero(replies[29])
              y = Utils.NaN2Zero(replies[30])
              chatBanEndTime = Utils.NaN2Zero(replies[35])

              # Check Password
              bcrypt.compare player.pw, pw, (err, res) =>
                unless res
                  player.connection.sendUTF8 "invalidlogin"
                  player.connection.close "Wrong Password: " + player.name
                  return
                d = new Date()
                lastLoginTimeDate = new Date(lastLoginTime)
                if lastLoginTimeDate.getDate() isnt d.getDate() and pubPoint > 0
                  targetInventoryNumber = -1
                  if inventory[0] is "burger"
                    targetInventoryNumber = 0
                  else if inventory[1] is "burger"
                    targetInventoryNumber = 1
                  else if inventory[0] is null
                    targetInventoryNumber = 0
                  else targetInventoryNumber = 1  if inventory[1] is null
                  if targetInventoryNumber >= 0
                    pubPoint = 100  if pubPoint > 100
                    inventory[targetInventoryNumber] = "burger"
                    inventoryNumber[targetInventoryNumber] += pubPoint * 10
                    @setInventory player.name, Types.getKindFromString("burger"), targetInventoryNumber, inventoryNumber[targetInventoryNumber]
                    @client.zrem "adrank", player.name

                # Check Ban
                d.setDate d.getDate() - d.getDay()
                d.setHours 0, 0, 0
                if lastLoginTime < d.getTime()
                  log.info player.name + "ban is initialized."
                  bannedTime = 0
                  @client.hset "b:" + player.connection._connection.remoteAddress, "time", bannedTime
                @client.hset "b:" + player.connection._connection.remoteAddress, "loginTime", curTime
                avatar = nextNewArmor  if player.name is pubTopName.toString()
                admin = null
                for i in [0...adminnames.length]
                  if adminnames[i] is player.name
                    admin = 1
                    log.info "Admin " + player.name + "login"
                log.info "Player name: " + player.name
                log.info "Armor: " + armor
                log.info "Weapon: " + weapon
                log.info "Experience: " + exp
                log.info "Banned Time: " + (new Date(bannedTime)).toString()
                log.info "Ban Use Time: " + (new Date(banUseTime)).toString()
                log.info "Last Login Time: " + lastLoginTimeDate.toString()
                log.info "Chatting Ban End Time: " + (new Date(chatBanEndTime)).toString()
                player.sendWelcome armor, weapon, avatar, weaponAvatar, exp, admin, bannedTime, banUseTime, inventory, inventoryNumber, achievementFound, achievementProgress, x, y, chatBanEndTime
        # this still the case where the user was found
        # we want to return, otherwise we close the connection
        return

      # Could not find the user
      player.connection.sendUTF8 "invalidlogin"
      player.connection.close "User does not exist: " + player.name

  createPlayer: (player) ->
    userKey = "u:" + player.name
    curTime = new Date().getTime()

    # Check if username is taken
    @client.sismember "usr", player.name, (err, reply) =>
      if reply is 1
        player.connection.sendUTF8 "userexists"
        player.connection.close "Username not available: " + player.name
      else
        # Add the player
        @client.multi()
          .sadd("usr", player.name)
          .hset(userKey, "pw", player.pw)
          .hset(userKey, "email", player.email)
          .hset(userKey, "armor", "clotharmor")
          .hset(userKey, "avatar", "clotharmor")
          .hset(userKey, "weapon", "sword1")
          .hset(userKey, "exp", 0)
          .hset("b:" + player.connection._connection.remoteAddress, "loginTime", curTime)
          .exec (err, replies) ->
            log.info "New User: " + player.name
            player.sendWelcome "clotharmor", "sword1", "clotharmor", "sword1", 0, null, 0, 0, [
              null
              null
            ], [
              0
              0
            ], [
              false
              false
              false
              false
              false
              false
            ], [
              0
              0
              0
              0
              0
              0
            ], player.x, player.y, 0

  checkBan: (player) ->
    @client.smembers "ipban", (err, replies) =>
      for index in [0...replies.length]
        if replies[index].toString() is player.connection._connection.remoteAddress
          @client.multi()
            .hget("b:" + player.connection._connection.remoteAddress, "rtime")
            .hget("b:" + player.connection._connection.remoteAddress, "time")
            .exec (err, replies) ->
              curTime = new Date()
              banEndTime = new Date(replies[0] * 1)
              log.info "curTime: " + curTime.toString()
              log.info "banEndTime: " + banEndTime.toString()
              if banEndTime.getTime() > curTime.getTime()
                player.connection.sendUTF8 "ban"
                player.connection.close "IP Banned player: " + player.name + " " + player.connection._connection.remoteAddress
          return

  banPlayer: (adminPlayer, banPlayer, days) ->
    @client.smembers "adminname", (err, replies) =>
      for index in [0...replies.length]
        if replies[index].toString() is adminPlayer.name
          curTime = (new Date()).getTime()
          @client.sadd "ipban", banPlayer.connection._connection.remoteAddress
          adminPlayer.server.pushBroadcast new Messages.Chat(banPlayer, "/1 " + adminPlayer.name + "-- 밴 ->" + banPlayer.name + " " + days + "일")
          setTimeout (-> banPlayer.connection.close "Added IP Banned player: #{banPlayer.name} #{banPlayer.connection._connection.remoteAddress}"), 30000
          @client.hset "b:" + banPlayer.connection._connection.remoteAddress, "rtime", (curTime + (days * 24 * 60 * 60 * 1000)).toString()
          log.info adminPlayer.name + "-- BAN ->" + banPlayer.name + " to " + (new Date(curTime + (days * 24 * 60 * 60 * 1000)).toString())
          return

  chatBan: (adminPlayer, targetPlayer) ->
    @client.smembers "adminname", (err, replies) =>
      for index in [0...replies.length]
        if replies[index].toString() is adminPlayer.name
          curTime = (new Date()).getTime()
          adminPlayer.server.pushBroadcast new Messages.Chat(targetPlayer, "/1 " + adminPlayer.name + "-- 채금 ->" + targetPlayer.name + " 10분")
          targetPlayer.chatBanEndTime = curTime + (10 * 60 * 1000)
          @client.hset "cb:" + targetPlayer.connection._connection.remoteAddress, "etime", (targetPlayer.chatBanEndTime).toString()
          log.info adminPlayer.name + "-- Chatting BAN ->" + targetPlayer.name + " to " + (new Date(targetPlayer.chatBanEndTime).toString())
          return

  newBanPlayer: (adminPlayer, banPlayer) ->
    log.debug "1"
    if adminPlayer.experience > 100000
      log.debug "2"
      @client.hget "b:" + adminPlayer.connection._connection.remoteAddress, "banUseTime", (err, reply) =>
        log.debug "3"
        curTime = new Date()
        log.debug "curTime: " + curTime.getTime()
        log.debug "bannable Time: " + (reply * 1) + 1000 * 60 * 60 * 24
        if curTime.getTime() > (reply * 1) + 1000 * 60 * 60 * 24
          log.debug "4"
          banPlayer.bannedTime++
          banMsg = "" + adminPlayer.name + "-- 밴 ->" + banPlayer.name + " " + banPlayer.bannedTime + "번째 " + (Math.pow(2, (banPlayer.bannedTime)) / 2) + "분"
          @client.sadd "ipban", banPlayer.connection._connection.remoteAddress
          @client.hset "b:" + banPlayer.connection._connection.remoteAddress, "rtime", (curTime.getTime() + (Math.pow(2, (banPlayer.bannedTime)) * 500 * 60)).toString()
          @client.hset "b:" + banPlayer.connection._connection.remoteAddress, "time", banPlayer.bannedTime.toString()
          @client.hset "b:" + adminPlayer.connection._connection.remoteAddress, "banUseTime", curTime.getTime().toString()
          setTimeout (->
            banPlayer.connection.close "Added IP Banned player: " + banPlayer.name + " " + banPlayer.connection._connection.remoteAddress
            return
          ), 30000
          adminPlayer.server.pushBroadcast new Messages.Chat(banPlayer, "/1 " + banMsg)
          log.info banMsg

  banTerm: (time) ->
    Math.pow(2, time) * 500 * 60

  equipArmor: (name, armor) ->
    log.info "Set Armor: " + name + " " + armor
    @client.hset "u:" + name, "armor", armor

  equipAvatar: (name, armor) ->
    log.info "Set Avatar: " + name + " " + armor
    @client.hset "u:" + name, "avatar", armor

  equipWeapon: (name, weapon) ->
    log.info "Set Weapon: " + name + " " + weapon
    @client.hset "u:" + name, "weapon", weapon

  setExp: (name, exp) ->
    log.info "Set Exp: " + name + " " + exp
    @client.hset "u:" + name, "exp", exp

  setInventory: (name, itemKind, inventoryNumber, itemNumber) ->
    if itemKind
      @client.hset "u:" + name, "inventory" + inventoryNumber, Types.getKindAsString(itemKind)
      @client.hset "u:" + name, "inventory" + inventoryNumber + ":number", itemNumber
      log.info "SetInventory: " + name + ", " + Types.getKindAsString(itemKind) + ", " + inventoryNumber + ", " + itemNumber
    else
      @makeEmptyInventory name, inventoryNumber

  makeEmptyInventory: (name, number) ->
    log.info "Empty Inventory: " + name + " " + number
    @client.hdel "u:" + name, "inventory" + number
    @client.hdel "u:" + name, "inventory" + number + ":number"

  foundAchievement: (name, number) ->
    log.info "Found Achievement: " + name + " " + number
    @client.hset "u:" + name, "achievement" + number + ":found", "true"

  progressAchievement: (name, number, progress) ->
    log.info "Progress Achievement: " + name + " " + number + " " + progress
    @client.hset "u:" + name, "achievement" + number + ":progress", progress

  setUsedPubPts: (name, usedPubPts) ->
    log.info "Set Used Pub Points: " + name + " " + usedPubPts
    @client.hset "u:" + name, "usedPubPts", usedPubPts

  setCheckpoint: (name, x, y) ->
    log.info "Set Check Point: " + name + " " + x + " " + y
    @client.hset "u:" + name, "x", x
    @client.hset "u:" + name, "y", y

  loadBoard: (player, command, number, replyNumber) ->
    log.info "Load Board: #{player.name} #{command} #{number} #{replyNumber}"

    switch command
      when "view"
        @client.multi()
          .hget("bo:free", number + ":title")
          .hget("bo:free", number + ":content")
          .hget("bo:free", number + ":writer")
          .hincrby("bo:free", number + ":cnt", 1)
          .smembers("bo:free:" + number + ":up")
          .smembers("bo:free:" + number + ":down")
          .hget("bo:free", number + ":time")
          .exec (err, replies) ->
            title = replies[0]
            content = replies[1]
            writer = replies[2]
            counter = replies[3]
            up = replies[4].length
            down = replies[5].length
            time = replies[6]
            player.send [
              Types.Messages.BOARD
              "view"
              title
              content
              writer
              counter
              up
              down
              time
            ]

      when "reply"
        @client.multi()
          .hget("bo:free", number + ":reply:" + replyNumber + ":writer")
          .hget("bo:free", number + ":reply:" + replyNumber + ":content")
          .smembers("bo:free:" + number + ":reply:" + replyNumber + ":up")
          .smembers("bo:free:" + number + ":reply:" + replyNumber + ":down")
          .hget("bo:free", number + ":reply:" + (replyNumber + 1) + ":writer")
          .hget("bo:free", number + ":reply:" + (replyNumber + 1) + ":content")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 1) + ":up")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 1) + ":down")
          .hget("bo:free", number + ":reply:" + (replyNumber + 2) + ":writer")
          .hget("bo:free", number + ":reply:" + (replyNumber + 2) + ":content")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 2) + ":up")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 2) + ":down")
          .hget("bo:free", number + ":reply:" + (replyNumber + 3) + ":writer")
          .hget("bo:free", number + ":reply:" + (replyNumber + 3) + ":content")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 3) + ":up")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 3) + ":down")
          .hget("bo:free", number + ":reply:" + (replyNumber + 4) + ":writer")
          .hget("bo:free", number + ":reply:" + (replyNumber + 4) + ":content")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 4) + ":up")
          .smembers("bo:free:" + number + ":reply:" + (replyNumber + 4) + ":down")
          .exec (err, replies) ->
            player.send [
              Types.Messages.BOARD
              "reply"
              replies[0]
              replies[1]
              replies[2].length
              replies[3].length
              replies[4]
              replies[5]
              replies[6].length
              replies[7].length
              replies[8]
              replies[9]
              replies[10].length
              replies[11].length
              replies[12]
              replies[13]
              replies[14].length
              replies[15].length
              replies[16]
              replies[17]
              replies[18].length
              replies[19].length
            ]

      when "up"
        @client.sadd "bo:free:" + number + ":up", player.name  if player.level >= 50

      when "down"
        @client.sadd "bo:free:" + number + ":down", player.name  if player.level >= 50

      when "replyup"
        @client.sadd "bo:free:" + number + ":reply:" + replyNumber + ":up", player.name  if player.level >= 50

      when "replydown"
        @client.sadd "bo:free:" + number + ":reply:" + replyNumber + ":down", player.name  if player.level >= 50

      when "list"
        @client.hget "bo:free", "lastnum", (err, reply) =>
          lastnum = reply
          lastnum = number  if number > 0
          @client.multi()
            .hget("bo:free", lastnum + ":title")
            .hget("bo:free", (lastnum - 1) + ":title")
            .hget("bo:free", (lastnum - 2) + ":title")
            .hget("bo:free", (lastnum - 3) + ":title")
            .hget("bo:free", (lastnum - 4) + ":title")
            .hget("bo:free", (lastnum - 5) + ":title")
            .hget("bo:free", (lastnum - 6) + ":title")
            .hget("bo:free", (lastnum - 7) + ":title")
            .hget("bo:free", (lastnum - 8) + ":title")
            .hget("bo:free", (lastnum - 9) + ":title")
            .hget("bo:free", lastnum + ":writer")
            .hget("bo:free", (lastnum - 1) + ":writer")
            .hget("bo:free", (lastnum - 2) + ":writer")
            .hget("bo:free", (lastnum - 3) + ":writer")
            .hget("bo:free", (lastnum - 4) + ":writer")
            .hget("bo:free", (lastnum - 5) + ":writer")
            .hget("bo:free", (lastnum - 6) + ":writer")
            .hget("bo:free", (lastnum - 7) + ":writer")
            .hget("bo:free", (lastnum - 8) + ":writer")
            .hget("bo:free", (lastnum - 9) + ":writer")
            .hget("bo:free", lastnum + ":cnt")
            .hget("bo:free", (lastnum - 1) + ":cnt")
            .hget("bo:free", (lastnum - 2) + ":cnt")
            .hget("bo:free", (lastnum - 3) + ":cnt")
            .hget("bo:free", (lastnum - 4) + ":cnt")
            .hget("bo:free", (lastnum - 5) + ":cnt")
            .hget("bo:free", (lastnum - 6) + ":cnt")
            .hget("bo:free", (lastnum - 7) + ":cnt")
            .hget("bo:free", (lastnum - 8) + ":cnt")
            .hget("bo:free", (lastnum - 9) + ":cnt")
            .smembers("bo:free:" + lastnum + ":up")
            .smembers("bo:free:" + (lastnum - 1) + ":up")
            .smembers("bo:free:" + (lastnum - 2) + ":up")
            .smembers("bo:free:" + (lastnum - 3) + ":up")
            .smembers("bo:free:" + (lastnum - 4) + ":up")
            .smembers("bo:free:" + (lastnum - 5) + ":up")
            .smembers("bo:free:" + (lastnum - 6) + ":up")
            .smembers("bo:free:" + (lastnum - 7) + ":up")
            .smembers("bo:free:" + (lastnum - 8) + ":up")
            .smembers("bo:free:" + (lastnum - 9) + ":up")
            .smembers("bo:free:" + lastnum + ":down")
            .smembers("bo:free:" + (lastnum - 1) + ":down")
            .smembers("bo:free:" + (lastnum - 2) + ":down")
            .smembers("bo:free:" + (lastnum - 3) + ":down")
            .smembers("bo:free:" + (lastnum - 4) + ":down")
            .smembers("bo:free:" + (lastnum - 5) + ":down")
            .smembers("bo:free:" + (lastnum - 6) + ":down")
            .smembers("bo:free:" + (lastnum - 7) + ":down")
            .smembers("bo:free:" + (lastnum - 8) + ":down")
            .smembers("bo:free:" + (lastnum - 9) + ":down")
            .hget("bo:free", lastnum + ":replynum")
            .hget("bo:free", (lastnum + 1) + ":replynum")
            .hget("bo:free", (lastnum + 2) + ":replynum")
            .hget("bo:free", (lastnum + 3) + ":replynum")
            .hget("bo:free", (lastnum + 4) + ":replynum")
            .hget("bo:free", (lastnum + 5) + ":replynum")
            .hget("bo:free", (lastnum + 6) + ":replynum")
            .hget("bo:free", (lastnum + 7) + ":replynum")
            .hget("bo:free", (lastnum + 8) + ":replynum")
            .hget("bo:free", (lastnum + 9) + ":replynum")
            .exec (err, replies) ->
              i = 0
              msg = [
                Types.Messages.BOARD
                "list"
                lastnum
              ]
              i = 0
              while i < 30
                msg.push replies[i]
                i++
              i = 30
              while i < 50
                msg.push replies[i].length
                i++
              i = 50
              while i < 60
                msg.push replies[i]
                i++
              player.send msg

  writeBoard: (player, title, content) ->
    log.info "Write Board: " + player.name + " " + title
    @client.hincrby "bo:free", "lastnum", 1, (err, reply) =>
      curTime = new Date().getTime()
      number = (if reply then reply else 1)
      @client.multi()
        .hset("bo:free", number + ":title", title)
        .hset("bo:free", number + ":content", content)
        .hset("bo:free", number + ":writer", player.name)
        .hset("bo:free", number + ":time", curTime)
        .exec()
      player.send [
        Types.Messages.BOARD
        "view"
        title
        content
        player.name
        0
        0
        0
        curTime
      ]

  writeReply: (player, content, number) ->
    log.info "Write Reply: " + player.name + " " + content + " " + number
    @client.hincrby "bo:free", number + ":replynum", 1, (err, reply) =>
      replyNum = (if reply then reply else 1)
      @client.multi()
        .hset("bo:free", number + ":reply:" + replyNum + ":content", content)
        .hset("bo:free", number + ":reply:" + replyNum + ":writer", player.name)
        .exec (err, replies) ->
          player.send [
            Types.Messages.BOARD
            "reply"
            player.name
            content
          ]

  pushKungWord: (player, word) ->
    server = player.server
    return if player is server.lastKungPlayer
    return if server.isAlreadyKung(word)
    return unless server.isRightKungWord(word)

    if server.kungWords.length is 0
      @client.srandmember "dic", (err, reply) ->
        randWord = reply
        server.pushKungWord player, randWord

    else
      @client.sismember "dic", word, (err, reply) ->
        if reply is 1
          server.pushKungWord player, word
        else
          player.send [
            Types.Messages.NOTIFY
            word + "는 사전에 없습니다."
          ]

module.exports = DatabaseHandler
