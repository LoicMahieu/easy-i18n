
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
  @fallback = require './middlewares/fallback-translate'

  ## Language detection
  detection = require './detection'
  @[k] = f for k, f of detection

  constructor: (options) ->
    unless @ instanceof I18n
      return new I18n(options)

    @options = _.extend(
      supported_languages: ['fr', 'nl', 'en']
      default_language: 'fr'
      resources: null
    , options)

    # Logger
    @logger = @options.logger or new winston.Logger()

    @namespaces = @options.resources or {}

  use: (middleware) ->
    middleware(@)
    @

  ## Translation handling

  load: (language, ns, cb) ->
    if @namespaces[ns]?[language]
      return cb(null)

    unless @backend
      throw new Error("No backend is provided.")

    @backend.load language, ns, (err, resources) =>
      return cb(err) if err

      @logger.debug "Loaded #{language}/#{ns}", resources

      @namespaces[ns] = {} unless @namespaces[ns]
      @namespaces[ns][language] = {} unless @namespaces[ns][language]
      @namespaces[ns][language] = resources
      @emit 'nsLoaded', language, ns, resources
      cb(null, resources)

    @

  translate: (language, ns, key, options = {}) ->
    options.missing = true unless options.missing == false

    res = @namespaces[ns]?[language]?[key]

    @emit 'translate', language, ns, key, res if res

    if res or not options.missing
      return res
    else
      return @missing(language, ns, key)

  missing: (language, ns, key) ->
    @emit 'missing', language, ns, key
    language + '/' + ns + ':' + key

  modify: (language, ns, key, value, propagateEvent = true, cb = noop) ->
    if typeof propagateEvent == 'function'
      cb = propagateEvent
      propagateEvent = true

    @load language, ns, (err) =>
      if err
        @logger.warn err
        return cb(err)

      if @namespaces[ns][language][key] != value
        @namespaces[ns][language][key] = value
        @emit 'modify', language, ns, key, value if propagateEvent
        @logger.debug('Modification', ns, language, key, value)
      else
        @logger.debug('Skipping modification', ns, language, key, value)
      
      cb(null)
    @

  dispose: ->
    @emit 'dispose'
    @backend = null
    @resource = null
    @options = null

module.exports = I18n
