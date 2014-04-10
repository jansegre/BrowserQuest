_ = require("underscore")
BISON = require("bison")
http = require("http")
url = require("url")
useBison = false
Utils = require("./utils")
miksagoConnection = require("websocket-server/lib/ws/connection")
worlizeRequest = require("websocket").request
wsServer = require("websocket-server")

WS = {}

###
Abstract Server and Connection classes
###
class Server
  constructor: (@port) ->

  onConnect: (@connectionCallback) ->

  onError: (@errorCallback) ->

  broadcast: (message) ->
    throw new Error "Not implemented"

  forEachConnection: (callback) ->
    _.each @_connections, callback

  addConnection: (connection) ->
    @_connections[connection.id] = connection

  removeConnection: (id) ->
    delete @_connections[id]

  getConnection: (id) ->
    @_connections[id]

class Connection
  constructor: (@id, @_connection, @_server) ->

  onClose: (@closeCallback) ->

  listen: (@listenCallback) ->

  broadcast: (message) ->
    throw new Error "Not implemented"

  send: (message) ->
    throw new Error "Not implemented"

  sendUTF8: (data) ->
    throw new Error "Not implemented"

  close: (logError) ->
    log.info "Closing connection to " + @_connection.remoteAddress + ". Error: " + logError
    @_connection.close()

###
MultiVersionWebsocketServer

Websocket server supporting draft-75, draft-76 and version 08+ of the WebSocket protocol.
Fallback for older protocol versions borrowed from https://gist.github.com/1219165
###
class WS.MultiVersionWebsocketServer extends Server

  worlizeServerConfig:
    # All options *except* 'httpServer' are required when bypassing
    # WebSocketServer.
    maxReceivedFrameSize: 0x10000
    maxReceivedMessageSize: 0x100000
    fragmentOutgoingMessages: true
    fragmentationThreshold: 0x4000
    keepalive: true
    keepaliveInterval: 20000
    assembleFragments: true
    # autoAcceptConnections is not applicable when bypassing WebSocketServer
    # autoAcceptConnections: false
    disableNagleAlgorithm: true
    closeTimeout: 5000
  _connections: {}
  _counter: 0

  constructor: (port, useOnePort, @ip) ->
    super port

    # Are we doing both client and server on one port?
    if useOnePort is true
      # Yes, we are

      # Use 'connect' for its static module
      connect = require("connect")
      app = connect()

      # Serve everything in the client subdir statically
      app.use connect.static("static")

      # Display errors (such as 404's) in the server log
      app.use connect.logger("dev")

      # Generate (on the fly) the pages needing special treatment
      app.use handleDynamicPageRequests = (request, response) =>
        path = url.parse(request.url).pathname
        switch path
          when "/status"
            # The server status page
            if @statusCallback
              response.writeHead 200
              response.write @statusCallback()
          # XXX: temporarily disabling this, is it necessary?
          #when "/config/config_build.json", "/config/config_local.json"
          #  # Generate the config_build/local.json files on the
          #  # fly, using the host address and port from the
          #  # incoming http header

          #  # Grab the incoming host:port request string
          #  headerPieces = request.connection.parser.incoming.headers.host.split(":", 2)

          #  # Determine new host string to give clients
          #  newHost = undefined
          #  if (typeof headerPieces[0] is "string") and (headerPieces[0].length > 0)
          #    # Seems like a valid string, lets use it
          #    newHost = headerPieces[0]
          #  else
          #    # The host value doesn't seem usable, so
          #    # fallback to the local interface IP address
          #    newHost = request.connection.address().address

          #  # Default port is 80
          #  newPort = 80
          #  if 2 is headerPieces.length
          #    # We've been given a 2nd value, maybe a port #
          #    if (typeof headerPieces[1] is "string") and (headerPieces[1].length > 0)
          #      # If a usable port value was given, use that instead
          #      tmpPort = parseInt(headerPieces[1], 10)
          #      newPort = tmpPort  if not isNaN(tmpPort) and (tmpPort > 0) and (tmpPort < 65536)

          #  # Assemble the config data structure
          #  newConfig =
          #    host: newHost
          #    port: newPort
          #    dispatcher: false

          #  # Make it JSON
          #  newConfigString = JSON.stringify(newConfig)

          #  # Create appropriate http headers
          #  responseHeaders =
          #    "Content-Type": "application/json"
          #    "Content-Length": newConfigString.length

          #  # Send it all back to the client
          #  response.writeHead 200, responseHeaders
          #  response.end newConfigString
          #when "/common/file.js"
          #  # Sends the real common/file.js to the client
          #  sendFile "js/file.js", response, log
          #when "/common/types.js"
          #  # Sends the real common/types.js to the client
          #  sendFile "js/types.js", response, log
          else
            response.writeHead 404
        response.end()

      @_httpServer = http.createServer(app).listen port, @ip or undefined, serverEverythingListening = ->
        log.info "Server (everything) is listening on port " + port

    else
      # Only run the server side code
      @_httpServer = http.createServer (request, response) =>
        path = url.parse(request.url).pathname
        if (path is "/status") and @statusCallback
          response.writeHead 200
          response.write @statusCallback()
        else
          response.writeHead 404
        response.end()

      @_httpServer.listen port, @ip, serverOnlyListening = ->
        log.info "Server (only) is listening on port " + port

    @_miksagoServer = wsServer.createServer()
    @_miksagoServer.server = @_httpServer
    @_miksagoServer.addListener "connection", webSocketListener = (connection) =>
      # Add remoteAddress property
      connection.remoteAddress = connection._socket.remoteAddress

      # We want to use "sendUTF" regardless of the server implementation
      connection.sendUTF = connection.send

      c = new WS.MiksagoWebSocketConnection(@_createId(), connection, @)
      @connectionCallback c  if @connectionCallback
      @addConnection c

    @_httpServer.on "upgrade", httpUpgradeRequest = (req, socket, head) =>
      if typeof req.headers["sec-websocket-version"] isnt "undefined"
        # WebSocket hybi-08/-09/-10 connection (WebSocket-Node)
        wsRequest = new worlizeRequest(socket, req, @worlizeServerConfig)
        try
          wsRequest.readHandshake()
          wsConnection = wsRequest.accept(wsRequest.requestedProtocols[0], wsRequest.origin)
          c = new WS.WorlizeWebSocketConnection(@_createId(), wsConnection, @)
          @connectionCallback c  if @connectionCallback
          @addConnection c
        catch e
          console.log "WebSocket Request unsupported by WebSocket-Node: " + e.toString()
      else
        # WebSocket hixie-75/-76/hybi-00 connection (node-websocket-server)
        if req.method is "GET" and (req.headers.upgrade and req.headers.connection) and req.headers.upgrade.toLowerCase() is "websocket" and req.headers.connection.toLowerCase() is "upgrade"
          new miksagoConnection(@_miksagoServer.manager, @_miksagoServer.options, req, socket, head)

  _createId: ->
    "5" + Utils.random(99) + "" + (@_counter++)

  broadcast: (message) ->
    @forEachConnection (connection) ->
      connection.send message

  onRequestStatus: (@statusCallback) ->

###
Connection class for Websocket-Node (Worlize)
https://github.com/Worlize/WebSocket-Node
###
class WS.WorlizeWebSocketConnection extends Connection
  constructor: (id, connection, server) ->
    super id, connection, server
    @_connection.on "message", onConnectionMessage = (message) =>
      if @listenCallback
        if message.type is "utf8"
          if useBison
            @listenCallback BISON.decode(message.utf8Data)
          else
            try
              @listenCallback JSON.parse(message.utf8Data)
            catch e
              if e instanceof SyntaxError
                @close "Received message was not valid JSON."
              else
                throw e

    @_connection.on "close", onConnectionClose = (connection) =>
      @closeCallback()  if @closeCallback
      delete @_server.removeConnection(@id)

  send: (message) ->
    data = undefined
    if useBison
      data = BISON.encode(message)
    else
      data = JSON.stringify(message)
    @sendUTF8 data

  sendUTF8: (data) ->
    @_connection.sendUTF data

###
Connection class for websocket-server (miksago)
https://github.com/miksago/node-websocket-server
###
class WS.MiksagoWebSocketConnection extends Connection
  constructor: (id, connection, server) ->
    super id, connection, server

    @_connection.addListener "message", (message) =>
      if @listenCallback
        if useBison
          @listenCallback BISON.decode(message)
        else
          @listenCallback JSON.parse(message)

    @_connection.on "close", (connection) =>
      @closeCallback() if @closeCallback
      delete @_server.removeConnection(@id)

  send: (message) ->
    data = undefined
    if useBison
      data = BISON.encode(message)
    else
      data = JSON.stringify(message)
    @sendUTF8 data

  sendUTF8: (data) ->
    @_connection.send data

# Sends a file to the client
sendFile = (file, response, log) ->
  try
    fs = require("fs")
    realFile = fs.readFileSync(__dirname + "/../common/" + file)
    responseHeaders =
      "Content-Type": "text/javascript"
      "Content-Length": realFile.length

    response.writeHead 200, responseHeaders
    response.end realFile
  catch err
    response.writeHead 500
    log.error "Something went wrong when trying to send " + file
    log.error "Error stack: " + err.stack
  return

module.exports = WS
