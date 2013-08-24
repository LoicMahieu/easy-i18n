
events = require 'events'
winston = require 'winston'
_ = require 'lodash'

class I18n extends events.EventEmitter
  ## Middlewares
  @redisSync = require './middlewares/redis-sync'
  @sequelizeBackend = require './middlewares/sequelize-backend'

  ## Language detection
  detection = require './detection'
  @[k] = f for k, f of detection

  constructor: (options) ->
    unless @ instanceof I18n
      return new I18n(options)

    @_options = _.extend(
      supported_languages: ['fr', 'nl', 'en']
      default_language: 'fr'
      locale_on_url: true
    , options)

    # Logger
    @logger = new winston.Logger()

    @namespaces = {}

    ## Express/Connect middleware
    @middleware = require('./express').bind(@)

  use: (middleware) ->
    middleware(@)
    @

  ## Translation handling

  ns: (ns) ->
    @namespaces[ns]

  loadNS: (ns, language, cb) ->
    if @namespaces[ns]?[language]
      return cb(null)

    unless @backend
      throw new Error("No backend is provided.")

    @backend.load namespace, language, (err, resources) =>
      return cb(err) if err

      @namespaces?[ns] = {}
      @namespaces[ns][language] = resources
      @emit 'nsLoaded', namespace, language, resources
      cb(null, resources)

    @

  unload: (ns) ->
    # todo?

  translate: (ns, language, key) ->
    res = @namespaces[ns]?[language]?[key]

    @emit 'missing', language, key unless res
    @emit 'translate', language, key, res if res

    res || key

  change: (ns, language, key, value, propagateEvent = true, cb) ->
    if typeof propagateEvent == 'function'
      cb = propagateEvent
      propagateEvent = true

    @load ns, language, (err) =>
      return cb(err) if err
      
      @namespaces[ns][language][key] = value
      @emit 'change', language, key, value if propagateEvent
      
      cb(null)
    @

  dispose: ->
    @emit 'dispose'
    @backend = null
    @resource = null
    @_options = null

module.exports = I18n
