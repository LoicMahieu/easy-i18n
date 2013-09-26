
Mustache = require 'mustache'

module.exports = () ->
  (i18n) ->
    i18n.formatTranslation = (translation, options) ->
      Mustache.render(translation, options)
