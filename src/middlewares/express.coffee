
_ = require 'lodash'
async = require 'async'
{EventEmitter} = require 'events'

detection = require '../detection'

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
  
  return lang

preload = (i18n, nss, langs, cb) ->
  tasks = []

  nss.forEach (ns) =>
    langs.forEach (language) =>
      tasks.push (cb) => i18n.load language, ns, cb

  async.parallel tasks, cb

parseTranslationKey = (key, defaultLang) ->
  # language/namespace:key
  # namespace:key
  keys = key.split ':'
  
  if keys < 2
    throw new Error('Invalid translation key: ', key)

  part = keys.shift().split('/')
  if part.length < 2
    part.unshift defaultLang

  keys = part.concat(keys)

class I18nExpress extends EventEmitter
  constructor: (@req, @res, @next, @options, @i18n) ->
    _language = ''
    @req.i18n =
      _i18n: @i18n
      translate: @translate

    Object.defineProperty @req.i18n, 'language',
      get: () => _language
      set: (v) =>
        prev = _language
        _language = v
        if prev != _language
          @setCookie()
          @emit 'languageChange', _language

    @req.i18n.lang = @req.i18n.language

    if @options.preload_namespaces.length and @options.preload_languages.length
      return preload @i18n, @options.preload_namespaces, @options.preload_languages, () =>
        @defineLanguage()
        @next()

    @defineLanguage()
    @next()

  translate: (key) =>
    args = _.toArray(arguments)

    if args.length == 1
      args = parseTranslationKey(args[0], @req.i18n.language)

    if args.length == 2
      args = [@req.i18n.language].concat(args)

    @i18n.translate.apply(@i18n, args)

  defineLanguage: () =>
    lang = null

    unless @options.supported_languages and @options.supported_languages.length
      return

    # Determine language
    if @options.locale_on_url
      lang = checkUrlLocale @req, @options.supported_languages

      # Redirect if language missing
      if @options.redirect_on_missing_on_url and not lang
        # TODO: Find another trick to don't trigger next middleware :(
        @next = () ->
        return @res.redirect('/' + @bestLanguage() + @req.url)
      else if not lang
        lang = @bestLanguage()

    else
      lang = @bestLanguage()

    @req.i18n.language = lang

  bestLanguage: () ->
    lang = @resolveCookie() || @resolveAcceptLanguage()

  setCookie: () =>
    unless @options.cookie_name and @res.cookie
      return

    cookieName = @options.cookie_name.name or @options.cookie_name
    cookieOptions = if _.isObject(@options.cookie_name) then @options.cookie_name
    @res.cookie(cookieName, @req.i18n.language, cookieOptions)

  resolveCookie: () ->
    unless @options.cookie_name
      return

    cookieName = @options.cookie_name.name or @options.cookie_name

    lang = @req.cookies?[@options.cookie_name]

    unless lang
      return

    unless detection.isSupported(lang, @options.supported_languages)
      return

    lang

  resolveAcceptLanguage: () ->
    langs = detection.parseAcceptLanguage(@req.i18n.language or @req.headers['accept-language'])
    lang = detection.bestLanguage(langs, @options.supported_languages, "unknown")
    if lang == 'unknown'
      return
    else
      return lang

module.exports = (options) ->
  (i18n) ->
    options = _.extend(
      supported_languages: ['en']
      default_language: 'en'
      locale_on_url: false
      redirect_on_missing_on_url: false
      cookie_name: null
      preload_namespaces: []
      preload_languages: []
    , options)

    i18n.express = (req, res, next) ->
      new I18nExpress(req, res, next, options, i18n)

    i18n.express.load = (ns, languages) ->
      _ns = if _.isArray(ns) then ns else [ ns ]

      (req, res, next) ->
        lngs = languages or req.i18n.language or options.supported_languages
        lngs = [ lngs ] unless _.isArray(lngs)

        loadLanguages = (ns, done) ->
          async.each lngs, ((lang, cb) ->
            i18n.load(lang, ns, cb)
          ), done

        async.each(_ns, loadLanguages, (err) ->
          if err
            i18n.logger.error(err)
            next(err)

          i18n.logger.debug(
            "Express: end loading" +
            " Namespaces:#{_ns.join(', ')}" +
            " Languages: #{lngs.join(', ')}"
          )
          next()
        )

