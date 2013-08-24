
events = require 'events'
winston = require 'winston'
_ = require 'lodash'

noop = () ->


class I18n extends events.EventEmitter
  ## Middlewares
  @redisSync = require './middlewares/redis-sync'
  @sequelizeBackend = require './middlewares/sequelize-backend'
  @loggerConsole = require './middlewares/logger-console'
  @express = require './middlewares/express'

  ## Language detection
  detection = require './detection'
  @[k] = f for k, f of detection

  constructor: (options) ->
    unless @ instanceof I18n
      return new I18n(options)

    @options = _.extend(
      supported_languages: ['fr', 'nl', 'en']
      default_language: 'fr'
    , options)

    # Logger
    @logger = new winston.Logger()

    @namespaces = {}

  use: (middleware) ->
    middleware(@)
    @

  ## Translation handling

  ns: (ns) ->
    @namespaces[ns]

  load: (language, ns, cb) ->
    if @namespaces[ns]?[language]
      return cb(null)

    unless @backend
      throw new Error("No backend is provided.")

    @backend.load language, ns, (err, resources) =>
      return cb(err) if err

      @namespaces?[ns] = {}
      @namespaces[ns][language] = resources
      @emit 'nsLoaded', language, ns, resources
      cb(null, resources)

    @

  unload: (ns) ->
    # todo?

  translate: (language, ns, key) ->
    res = @namespaces[ns]?[language]?[key]

    @emit 'missing', language, ns, key unless res
    @emit 'translate', language, ns, key, res if res

    res || language + '/' + ns + ':' + key

  change: (language, ns, key, value, propagateEvent = true, cb = noop) ->
    if typeof propagateEvent == 'function'
      cb = propagateEvent
      propagateEvent = true

    @load language, ns, (err) =>
      if err
        @logger.warn err
        return cb(err)
      
      @namespaces[ns][language][key] = value
      @emit 'change', language, ns, key, value if propagateEvent
      
      cb(null)
    @

  dispose: ->
    @emit 'dispose'
    @backend = null
    @resource = null
    @options = null

module.exports = I18n
