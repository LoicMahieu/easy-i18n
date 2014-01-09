
util = require 'util'

module.exports =
  ###
  # Parses the HTTP accept-language header and returns a
  # sorted array of objects. Example object:
  # {
  #   lang: 'pl', quality: 0.7
  # }
  ###
  parseAcceptLanguage: (header) ->
    # pl,fr-FR;q=0.3,en-US;q=0.1

    if not header or not header.split
      return []

    raw_langs = header.split(",")

    langs = raw_langs.map (raw_lang) ->
      parts = raw_lang.split(";")
      q = 1

      if parts.length > 1 and parts[1].indexOf("q=") is 0
        qval = parseFloat(parts[1].split("=")[1])
        q = qval if isNaN(qval) is false

      lang: parts[0].trim()
      quality: q

    langs.sort (a, b) ->
      if a.quality is b.quality
        0
      else if a.quality < b.quality
        1
      else
        -1

  # Given the user's prefered languages and a list of currently
  # supported languages, returns the best match or a default language.
  #
  # languages must be a sorted list, the first match is returned.
  bestLanguage: (languages, supported_languages, defaultLanguage) ->
    lower = supported_languages.map (l) -> l.toLowerCase()

    for lq in languages
      if lower.indexOf(lq.lang.toLowerCase()) isnt -1
        return lq.lang
      else if lower.indexOf(lq.lang.split("-")[0].toLowerCase()) isnt -1
        return lq.lang.split("-")[0]

    defaultLanguage

  isSupported: (language, supported_languages) ->
    supported_languages.indexOf(language) >= 0


  # Given a language code, return a locale code the OS understands.
  # language: en-US
  # locale:   en_US
  localeFrom: (language) ->
    if not language or not language.split
      return ""

    parts = language.split("-")

    if parts.length is 1
      parts[0].toLowerCase()

    else if parts.length is 2
      util.format "%s_%s", parts[0].toLowerCase(), parts[1].toUpperCase()

    else if parts.length is 3
      util.format "%s_%s", parts[0].toLowerCase(), parts[2].toUpperCase()

    else
      # Todo: don't use directly console
      console.error util.format("Unable to map a local from language code [%s]", language)
      language

  # Given a locale code, return a language code
  languageFrom: (locale) ->
    if not locale or not locale.split
      return ""

    parts = locale.split("_")

    if parts.length is 1
      parts[0].toLowerCase()

    else if parts.length is 2
      util.format "%s-%s", parts[0].toLowerCase(), parts[1].toUpperCase()

    else if parts.length is 3
      util.format "%s-%s", parts[0].toLowerCase(), parts[2].toUpperCase()

    else
      # Todo: don't use directly console
      logger.error util.format("Unable to map a language from locale code [%s]", locale)
      locale
