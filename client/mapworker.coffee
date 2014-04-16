###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

_ = require("underscore")
mapData = require("./maps/world_client")

global.onmessage = (event) ->
  generateCollisionGrid()
  generatePlateauGrid()
  postMessage mapData

generateCollisionGrid = ->
  mapData.grid = []

  for i in [0...mapData.height]
    mapData.grid[i] = []
    for j in [0...mapData.width]
      mapData.grid[i][j] = 0

  _.each mapData.collisions, (tileIndex) ->
    pos = tileIndexToGridPosition(tileIndex + 1)
    mapData.grid[pos.y][pos.x] = 1

  _.each mapData.blocking, (tileIndex) ->
    pos = tileIndexToGridPosition(tileIndex + 1)
    mapData.grid[pos.y][pos.x] = 1 if mapData.grid[pos.y]?

generatePlateauGrid = ->
  tileIndex = 0
  mapData.plateauGrid = []

  for i in [0...mapData.height]
    mapData.plateauGrid[i] = []
    for j in [0...mapData.width]
      if _.include(mapData.plateau, tileIndex)
        mapData.plateauGrid[i][j] = 1
      else
        mapData.plateauGrid[i][j] = 0
      tileIndex += 1

getX = (num, w) ->
  return 0 if num is 0
  (if (num % w is 0) then w - 1 else (num % w) - 1)

tileIndexToGridPosition = (tileNum) ->
  x = 0
  y = 0

  #tileNum -= 1;
  #x = getX(tileNum + 1, mapData.width);
  #y = Math.floor(tileNum / mapData.width);
  x: getX(tileNum, mapData.width)
  y: Math.floor((tileNum - 1) / mapData.width)
