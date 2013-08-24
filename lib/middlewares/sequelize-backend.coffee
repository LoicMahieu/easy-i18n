
class Backend
  constructor: (@_model, @_i18n, @_options = {}) ->
    @_i18n.on 'change', @saveChange
    @_i18n.on 'translate', @increment if @_options.increment

  _find: (ns, language, key) ->
    where =
      namespace: ns
      language: language

    where.key = key if key
    
    @_model.find(where: where)

  _catchError: (err) =>
    @_i18n.logger.error err if err

  load: (ns, language, cb) ->
    @_model._find(ns, language).done (err, models) =>
      _catchError err if err

      res = {}
      for model in models
        res[model.language] = {} unless res[model.language]
        res[model.language][model.key] = model.value

      cb(res)

  saveChange: (ns, language, key, value) =>
    @_find(ns, language, key).done (err, model) =>
      _catchError err if err

      unless model
        model = @_model.build(
          namespace: ns
          language: language
          key: key
        )

      model.value = value
      model.save().done @_catchError

  increment: (ns, language, key, value) =>
    @_find(ns, language, key).done (err, model) =>
      _catchError err if err
      model.increment('used', 1).done @_catchError if model

module.exports = (sequelize, options) ->
  (i18n) ->
    model = sequelize.import __dirname + '/sequelize-backend-model'
    i18n.backend = new Backend(model, i18n, options)
