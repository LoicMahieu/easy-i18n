
_ = require 'lodash'
async = require 'async'


class Backend
  constructor: (@_model, @_i18n, _options = {}) ->
    @_options = _.extend
      save_missing: true
    , _options
    @_i18n.on 'modify', @saveModify
    @_i18n.on 'translate', @increment if @_options.increment
    @_i18n.on 'missing', @saveMissing if @_options.save_missing
    @_queues = {}

  _findAll: (language, ns, key) ->
    where =
      namespace: ns
      language: language

    where.key = key if key
    
    @_model.findAll(where: where)

  _find: (language, ns, key) ->
    where =
      namespace: ns
      language: language

    where.key = key if key
    
    @_model.find(where: where)

  _catchError: (err, cb) =>
    if err
      @_i18n.logger.error err
      cb?(err)

  load: (language, ns, cb) ->
    @_findAll(language, ns).done (err, models) =>
      return @_catchError err, cb if err

      res = {}
      
      if models
        for model in models
          res[model.key] = model.value

      cb(null, res)

  saveModify: (language, ns, key, value) =>
    queue = @_createSaveQueue(language, ns, key)
    queue.push(value: value, @_catchError)

  saveMissing: (language, ns, key, options) =>
    @_i18n.logger.debug("Save missing for #{language}/#{ns}:#{key}")
    queue = @_createSaveQueue(language, ns, key)

    value = ''
    if options.missing
      if typeof options.missing == 'object'
        value = options.missing[language] if options.missing[language]
      else
        value = options.missing

    queue.push(value: value, exitOnExist: true, @_catchError)

  _createSaveQueue: (language, ns, key) =>
    unless @_queues[language + ns + key]
      q = async.queue (task, cb) =>
        @_find(language, ns, key).done (err, model) =>
          return @_catchError err, cb if err
          
          if model and task.exitOnExist
            return cb()

          unless model
            model = @_model.build(
              namespace: ns
              language: language
              key: key
            )

          model.value = task.value
          model.save().done cb
      , 1

      # Delete queue when all tasks are processed
      q.drain = () => delete @_queues[language + ns + key]

      @_queues[language + ns + key] = q
    
    return @_queues[language + ns + key]

  dispose: ->
    # todo: sequelize stop
    @_model = null
    @_i18n = null
    @_options = null

  increment: (language, ns, key, value) =>
    @_find(language, ns, key).done (err, model) =>
      return @_catchError err if err
      model.increment('used', 1).done @_catchError if model

module.exports = (sequelize, options) ->
  (i18n) ->
    model = sequelize.import __dirname + '/sequelize-backend-model'
    i18n.backend = backend = new Backend(model, i18n, options)
    i18n.on 'dispose', ->
      backend.dispose()
      backend = null
