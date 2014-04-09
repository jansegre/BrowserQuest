_ = require("underscore")
$ = require("jquery")
log = require("./log")
Storage = require("./storage")
Types = require("./types")
Util = require("./util")

class App
  constructor: ->
    @currentPage = 1
    @blinkInterval = null
    @isParchmentReady = true
    @ready = false
    @storage = new Storage()
    @watchNameInputInterval = setInterval(@toggleButton.bind(this), 100)
    @initFormFields()
    if window.localStorage and window.localStorage.data
      @frontPage = "loadcharacter"
    else
      @frontPage = "createcharacter"

  setGame: (game) ->
    @game = game
    @isMobile = @game.renderer.mobile
    @isTablet = @game.renderer.tablet
    @isDesktop = not (@isMobile or @isTablet)
    @supportsWorkers = !!window.Worker
    @ready = true

  initFormFields: ->
    self = this

    # Play button
    @$play = $(".play")
    @getPlayButton = ->
      @getActiveForm().find ".play span"

    @setPlayButtonState true

    # Login form fields
    @$loginnameinput = $("#loginnameinput")
    @$loginpwinput = $("#loginpwinput")
    @loginFormFields = [
      this.$loginnameinput
      this.$loginpwinput
    ]

    # Create new character form fields
    @$nameinput = $("#nameinput")
    @$pwinput = $("#pwinput")
    @$pwinput2 = $("#pwinput2")
    @$email = $("#emailinput")
    @createNewCharacterFormFields = [
      this.$nameinput
      this.$pwinput
      this.$pwinput2
      this.$email
    ]

    # Functions to return the proper username / password fields to use, depending on which form
    # (login or create new character) is currently active.
    @getUsernameField = ->
      (if @createNewCharacterFormActive() then @$nameinput else @$loginnameinput)

    @getPasswordField = ->
      (if @createNewCharacterFormActive() then @$pwinput else @$loginpwinput)

  center: ->
    window.scrollTo 0, 1

  canStartGame: ->
    if @isDesktop
      @game and @game.map and @game.map.isLoaded
    else
      @game

  tryStartingGame: ->
    return if @starting # Already loading
    self = this
    action = (if @createNewCharacterFormActive() then "create" else "login")
    username = @getUsernameField().val()
    userpw = @getPasswordField().val()
    email = ""
    userpw2 = undefined
    global.un = @getUsernameField()
    if action is "create"
      email = @$email.val()
      userpw2 = @$pwinput2.val()
    return unless @validateFormFields(username, userpw, userpw2, email)
    @setPlayButtonState false
    if not @ready or not @canStartGame()
      watchCanStart = setInterval(->
        log.debug "waiting..."
        if self.canStartGame()
          clearInterval watchCanStart
          self.startGame action, username, userpw, email
      , 100)
    else
      @startGame action, username, userpw, email

  startGame: (action, username, userpw, email) ->
    self = this
    @firstTimePlaying = not self.storage.hasAlreadyPlayed()

    if username and not @game.started
      log.debug "Starting game..."
      @game.setServerOptions @config.host, @config.port, username, userpw, email

      # On mobile and tablet we load the map after the player has clicked
      # on the login/create button instead of loading it in a web worker.
      # See initGame in main.js.
      self.game.loadMap()  unless self.isDesktop
      @center()
      @game.run action, (result) ->
        if result.success is true
          self.start()
        else
          self.setPlayButtonState true
          switch result.reason
            when "invalidlogin"
              # Login information was not correct (either username or password)
              self.addValidationError null, "The username or password you entered is incorrect."
              self.getUsernameField().focus()

            when "userexists"
              # Attempted to create a new user, but the username was taken
              self.addValidationError self.getUsernameField(), "The username you entered is not available."

            when "invalidusername"
              # The username contains characters that are not allowed (rejected by the sanitizer)
              self.addValidationError self.getUsernameField(), "The username you entered contains invalid characters."

            when "loggedin"
              # Attempted to log in with the same user multiple times simultaneously
              self.addValidationError self.getUsernameField(), "A player with the specified username is already logged in."

            else
              self.addValidationError null, "Failed to launch the game: " + ((if result.reason then result.reason else "(reason unknown)"))

  start: ->
    @hideIntro()
    $("body").addClass "started"
    @toggleInstructions()  if @firstTimePlaying

  setPlayButtonState: (enabled) ->
    self = this
    $playButton = @getPlayButton()
    if enabled
      @starting = false
      @$play.removeClass "loading"
      $playButton.click ->
        self.tryStartingGame()
      $playButton.text @playButtonRestoreText  if @playButtonRestoreText

    else
      # Loading state
      @starting = true
      @$play.addClass "loading"
      $playButton.unbind "click"
      @playButtonRestoreText = $playButton.text()
      $playButton.text "Loading..."

  getActiveForm: ->
    if @loginFormActive()
      $ "#loadcharacter"
    else if @createNewCharacterFormActive()
      $ "#createcharacter"
    else
      null

  loginFormActive: ->
    $("#parchment").hasClass "loadcharacter"

  createNewCharacterFormActive: ->
    $("#parchment").hasClass "createcharacter"

  ###
  Performs some basic validation on the login / create new character forms (required fields are filled
  out, passwords match, email looks valid). Assumes either the login or the create new character form
  is currently active.
  ###
  validateFormFields: (username, userpw, userpw2, email) ->
    @clearValidationErrors()
    unless username
      @addValidationError @getUsernameField(), "Please enter a username."
      return false
    unless userpw
      @addValidationError @getPasswordField(), "Please enter a password."
      return false
    if @createNewCharacterFormActive() # In Create New Character form (rather than login form)
      unless userpw2
        @addValidationError @$pwinput2, "Please confirm your password by typing it again."
        return false
      if userpw isnt userpw2
        @addValidationError @$pwinput2, "The passwords you entered do not match. Please make sure you typed the password correctly."
        return false

      # Email field is not required, but if it's filled out, then it should look like a valid email.
      if email and not @validateEmail(email)
        @addValidationError @$email, "The email you entered appears to be invalid. Please enter a valid email (or leave the email blank)."
        return false
    true

  validateEmail: (email) ->
    # Regex borrowed from http://stackoverflow.com/a/46181/393005
    re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    re.test email

  addValidationError: (field, errorText) ->
    $("<span/>",
      class: "validation-error blink"
      text: errorText
    ).appendTo ".validation-summary"
    if field
      field.addClass("field-error").select()
      field.bind "keypress", (event) ->
        field.removeClass "field-error"
        $(".validation-error").remove()
        $(this).unbind event

  clearValidationErrors: ->
    fields = (if @loginFormActive() then @loginFormFields else @createNewCharacterFormFields)
    $.each fields, (i, field) ->
      field.removeClass "field-error"
    $(".validation-error").remove()

  setMouseCoordinates: (event) ->
    gamePos = $("#container").offset()
    scale = @game.renderer.getScaleFactor()
    width = @game.renderer.getWidth()
    height = @game.renderer.getHeight()
    mouse = @game.mouse
    mouse.x = event.pageX - gamePos.left - ((if @isMobile then 0 else 5 * scale))
    mouse.y = event.pageY - gamePos.top - ((if @isMobile then 0 else 7 * scale))
    if mouse.x <= 0
      mouse.x = 0
    else mouse.x = width - 1  if mouse.x >= width
    if mouse.y <= 0
      mouse.y = 0
    else mouse.y = height - 1  if mouse.y >= height


  # Init the hud that makes it show what creature you are mousing over and attacking
  initTargetHud: ->
    self = this
    scale = self.game.renderer.getScaleFactor()
    healthMaxWidth = $("#inspector .health").width() - (12 * scale)
    timeout = undefined
    @game.player.onSetTarget (target, name, mouseover) ->
      el = "#inspector"
      sprite = target.sprite
      if sprite?
        x = ((sprite.animationData.idle_down.length - 1) * sprite.width)
        y = ((sprite.animationData.idle_down.row) * sprite.height)
      else
        log.error "target #{target} has no sprite!"
      $(el + " .name").text name

      # Show how much Health creature has left. Currently does not work.
      # The reason health doesn't currently go down has to do with the lines below down to initExpBar
      if target.healthPoints
        $(el + " .health").css "width", Math.round(target.healthPoints / target.maxHp * 100) + "%"
      else
        $(el + " .health").css "width", "0%"
      level = Types.getMobLevel(Types.getKindFromString(name))
      if level?
        $(el + " .level").text "Level " + level
      else
        $("#inspector .level").text ""
      $(el).fadeIn "fast"

    self.game.onUpdateTarget (target) ->
      $("#inspector .health").css "width", Math.round(target.healthPoints / target.maxHp * 100) + "%"

    self.game.player.onRemoveTarget (targetId) ->
      $("#inspector").fadeOut "fast"
      $("#inspector .level").text ""
      self.game.player.inspecting = null

  initExpBar: ->
    maxHeight = $("#expbar").height()
    @game.onPlayerExpChange (expInThisLevel, expForLevelUp) ->
      barHeight = Math.round((maxHeight / expForLevelUp) * ((if expInThisLevel > 0 then expInThisLevel else 0)))
      $("#expbar").css "height", barHeight + "px"

  initHealthBar: ->
    scale = @game.renderer.getScaleFactor()
    healthMaxWidth = $("#healthbar").width() - (12 * scale)
    @game.onPlayerHealthChange (hp, maxHp) ->
      barWidth = Math.round((healthMaxWidth / maxHp) * ((if hp > 0 then hp else 0)))
      $("#hitpoints").css "width", barWidth + "px"

    @game.onPlayerHurt @blinkHealthBar.bind(this)

  blinkHealthBar: ->
    $hitpoints = $("#hitpoints")
    $hitpoints.addClass "white"
    setTimeout (->
      $hitpoints.removeClass "white"
    ), 500

  toggleButton: ->
    name = $("#parchment input").val()
    $play = $("#createcharacter .play")
    if name and name.length > 0
      $play.removeClass "disabled"
      $("#character").removeClass "disabled"
    else
      $play.addClass "disabled"
      $("#character").addClass "disabled"

  hideIntro: ->
    clearInterval @watchNameInputInterval
    $("body").removeClass "intro"
    setTimeout (->
      $("body").addClass "game"
    ), 500

  showChat: ->
    if @game.started
      $("#chatbox").addClass "active"
      $("#chatinput").focus()
      $("#chatbutton").addClass "active"

  hideChat: ->
    if @game.started
      $("#chatbox").removeClass "active"
      $("#chatinput").blur()
      $("#chatbutton").removeClass "active"

  toggleInstructions: ->
    if $("#achievements").hasClass("active")
      @toggleAchievements()
      $("#achievementsbutton").removeClass "active"
    $("#instructions").toggleClass "active"

  toggleAchievements: ->
    if $("#instructions").hasClass("active")
      @toggleInstructions()
      $("#helpbutton").removeClass "active"
    @resetPage()
    $("#achievements").toggleClass "active"

  resetPage: ->
    self = this
    $achievements = $("#achievements")
    if $achievements.hasClass("active")
      $achievements.bind Util.TRANSITIONEND, ->
        $achievements.removeClass("page" + self.currentPage).addClass "page1"
        self.currentPage = 1
        $achievements.unbind Util.TRANSITIONEND

  initEquipmentIcons: ->
    scale = @game.renderer.getScaleFactor()
    getIconPath = (spriteName) ->
      "img/" + scale + "/item-" + spriteName + ".png"

    weapon = @game.player.getWeaponName()
    armor = @game.player.getSpriteName()
    weaponPath = getIconPath(weapon)
    armorPath = getIconPath(armor)
    $("#weapon").css "background-image", "url(\"" + weaponPath + "\")"
    $("#armor").css "background-image", "url(\"" + armorPath + "\")"  if armor isnt "firefox"

  hideWindows: ->
    if $("#achievements").hasClass("active")
      @toggleAchievements()
      $("#achievementsbutton").removeClass "active"
    if $("#instructions").hasClass("active")
      @toggleInstructions()
      $("#helpbutton").removeClass "active"
    @closeInGameScroll "credits"  if $("body").hasClass("credits")
    @closeInGameScroll "legal"  if $("body").hasClass("legal")
    @closeInGameScroll "about"  if $("body").hasClass("about")

  showAchievementNotification: (id, name) ->
    $notif = $("#achievement-notification")
    $name = $notif.find(".name")
    $button = $("#achievementsbutton")
    $notif.removeClass().addClass "active achievement" + id
    $name.text name
    if @game.storage.getAchievementCount() is 1
      @blinkInterval = setInterval(->
        $button.toggleClass "blink"
      , 500)
    setTimeout (->
      $notif.removeClass "active"
      $button.removeClass "blink"
    ), 5000

  displayUnlockedAchievement: (id) ->
    $achievement = $("#achievements li.achievement" + id)
    achievement = @game.getAchievementById(id)
    @setAchievementData $achievement, achievement.name, achievement.desc  if achievement and achievement.hidden
    $achievement.addClass "unlocked"

  unlockAchievement: (id, name) ->
    @showAchievementNotification id, name
    @displayUnlockedAchievement id
    nb = parseInt($("#unlocked-achievements").text())
    $("#unlocked-achievements").text nb + 1

  initAchievementList: (achievements) ->
    self = this
    $lists = $("#lists")
    $page = $("#page-tmpl")
    $achievement = $("#achievement-tmpl")
    page = 0
    count = 0
    $p = null
    _.each achievements, (achievement) ->
      count++
      $a = $achievement.clone()
      $a.removeAttr "id"
      $a.addClass "achievement" + count
      self.setAchievementData $a, achievement.name, achievement.desc  unless achievement.hidden
      $a.find(".twitter").attr "href", "http://twitter.com/share?url=http%3A%2F%2Fbrowserquest.mozilla.org&text=I%20unlocked%20the%20%27" + achievement.name + "%27%20achievement%20on%20Mozilla%27s%20%23BrowserQuest%21&related=glecollinet:Creators%20of%20BrowserQuest%2Cwhatthefranck"
      $a.show()
      $a.find("a").click ->
        url = $(this).attr("href")
        self.openPopup "twitter", url
        false

      if (count - 1) % 4 is 0
        page++
        $p = $page.clone()
        $p.attr "id", "page" + page
        $p.show()
        $lists.append $p
      $p.append $a
    $("#total-achievements").text $("#achievements").find("li").length

  initUnlockedAchievements: (ids) ->
    self = this
    _.each ids, (id) ->
      self.displayUnlockedAchievement id
    $("#unlocked-achievements").text ids.length

  setAchievementData: ($el, name, desc) ->
    $el.find(".achievement-name").html name
    $el.find(".achievement-description").html desc

  toggleScrollContent: (content) ->
    currentState = $("#parchment").attr("class")
    if @game.started
      $("#parchment").removeClass().addClass content
      $("body").removeClass("credits legal about").toggleClass content
      $("body").toggleClass "death"  unless @game.player
      $("#helpbutton").removeClass "active"  if content isnt "about"
    else
      if currentState isnt "animate"
        if currentState is content
          @animateParchment currentState, @frontPage
        else
          @animateParchment currentState, content

  togglePopulationInfo: ->
    $("#population").toggleClass "visible"

  openPopup: (type, url) ->
    h = $(window).height()
    w = $(window).width()
    popupHeight = undefined
    popupWidth = undefined
    top = undefined
    left = undefined
    switch type
      when "twitter"
        popupHeight = 450
        popupWidth = 550
      when "facebook"
        popupHeight = 400
        popupWidth = 580
    top = (h / 2) - (popupHeight / 2)
    left = (w / 2) - (popupWidth / 2)
    newwindow = window.open(url, "name", "height=" + popupHeight + ",width=" + popupWidth + ",top=" + top + ",left=" + left)
    newwindow.focus()  if window.focus

  animateParchment: (origin, destination) ->
    self = this
    $parchment = $("#parchment")
    duration = 1
    if @isMobile
      $parchment.removeClass(origin).addClass destination
    else
      if @isParchmentReady
        duration = 0  if @isTablet
        @isParchmentReady = not @isParchmentReady
        $parchment.toggleClass "animate"
        $parchment.removeClass origin
        setTimeout (->
          $("#parchment").toggleClass "animate"
          $parchment.addClass destination
        ), duration * 1000
        setTimeout (->
          self.isParchmentReady = not self.isParchmentReady
        ), duration * 1000

  animateMessages: ->
    $messages = $("#notifications div")
    $messages.addClass "top"

  resetMessagesPosition: ->
    message = $("#message2").text()
    $("#notifications div").removeClass "top"
    $("#message2").text ""
    $("#message1").text message

  showMessage: (message) ->
    $wrapper = $("#notifications div")
    $message = $("#notifications #message2")
    @animateMessages()
    $message.text message
    @resetMessageTimer()  if @messageTimer
    @messageTimer = setTimeout(->
      $wrapper.addClass "top"
    , 5000)

  resetMessageTimer: ->
    clearTimeout @messageTimer

  resizeUi: ->
    if @game
      if @game.started
        @game.resize()
        @initHealthBar()
        @initTargetHud()
        @initExpBar()
        @game.updateBars()
      else
        newScale = @game.renderer.getScaleFactor()
        @game.renderer.rescale newScale

module.exports = App
