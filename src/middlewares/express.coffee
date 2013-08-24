
_ = require 'lodash'

detection = require('../detection')

checkUrlLocale = (req, supported_languages) ->
  # Given a URL, http://foo.com/ab/xyz/, we check to see if the first directory
  # is actually a locale we know about, and if so, we strip it out of the URL
  # (i.e., URL becomes http://foo.com/xyz/) and store that locale info on the
  # request's accept-header.
  matches = req.url.match /^\/([^\/]+)(\/|$)/
  return unless matches and matches[1]

  # Look for a lang we know about, and if found, strip it off the URL so routes
  # continue to work. If we don't find it (i.e., comes back "unknown") then bail.
  # We do this so that we don't falsely consume more of the URL than we should
  # and stip things that aren't actually locales we know about.
  parsed = detection.parseAcceptLanguage matches[1]
  lang = detection.bestLanguage parsed, supported_languages, "unknown"
  return if lang is "unknown"

  req.url = req.url.replace matches[0], '/'
  req.i18n.language = lang
  
  return lang

class I18nExpress
  constructor: (options, @i18n) ->
    @options = _.extend(
      supported_languages: ['en']
      default_language: 'en'
      locale_on_url: false
    , options)

  middleware: (req, res, next) =>
    req.i18n =
      _i18n: @i18n
      language: ''
      translate: (key) =>
        args = _.toArray(arguments)

        if args.length == 1
          args = @parseKey(req, args[0])

        if args.length == 2
          args = [req.i18n.language].concat(args)

        @i18n.translate.apply(@i18n, args)

    if @options.locale_on_url
      checkUrlLocale req, @options.supported_languages
    
    langs = detection.parseAcceptLanguage(req.i18n.language or req.headers['accept-language'])
    lang = detection.bestLanguage(langs, @options.supported_languages, @options.default_lang)

    req.i18n.language = lang

    next()

  parseKey: (req, key) ->
    keys = key.split ':'
    
    if keys < 2
      throw new Error('Invalid translation key: ', key)

    part = keys.shift().split('/')
    if part.length < 2
      part.unshift req.i18n.language

    keys = part.concat(keys)

module.exports = (options) ->
  (i18n) ->
    express = new I18nExpress(options, i18n)
    i18n.express = express.middleware
