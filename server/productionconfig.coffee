class ProductionConfig
  constructor: (@config) ->
    try
      @production = require("./production_hosts/#{@config.production}")
    catch err
      @production = null

  inProduction: ->
    return @production.isActive() if @production?
    false

  getProductionSettings: ->
    @production  if @inProduction()

module.exports = ProductionConfig
