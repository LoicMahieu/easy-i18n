
_ = require 'lodash'

module.exports = (options) ->
  options = _.extend(
    fallback_language: 'en'
  , options)

  (i18n) ->
    _missing = i18n.missing
    i18n.missing = (language, ns, key) ->
      if language == options.fallback_language
        return _missing.apply(i18n, arguments)
      else
        res = i18n.translate(options.fallback_language, ns, key, missing: false)
        if res
          return res
        else
          return _missing.apply(i18n, arguments)
