
detection = require('./detection')

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
  parsed = parseAcceptLanguage matches[1]
  lang = detection.bestLanguage parsed, supported_languages, "unknown"
  return if lang is "unknown"

  req.url = req.url.replace matches[0], '/'
  req.headers['accept-language'] = lang

module.exports = (req, res, next) ->
  if @_options.locale_on_url
    checkUrlLocale req, @_options.supported_languages
  
  console.log(req.headers);
  next();