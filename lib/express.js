// Generated by CoffeeScript 1.6.3
(function() {
  var checkUrlLocale, detection;

  detection = require('./detection');

  checkUrlLocale = function(req, supported_languages) {
    var lang, matches, parsed;
    matches = req.url.match(/^\/([^\/]+)(\/|$)/);
    if (!(matches && matches[1])) {
      return;
    }
    parsed = parseAcceptLanguage(matches[1]);
    lang = detection.bestLanguage(parsed, supported_languages, "unknown");
    if (lang === "unknown") {
      return;
    }
    req.url = req.url.replace(matches[0], '/');
    return req.headers['accept-language'] = lang;
  };

  module.exports = function(req, res, next) {
    if (this._options.locale_on_url) {
      checkUrlLocale(req, this._options.supported_languages);
    }
    console.log(req.headers);
    return next();
  };

}).call(this);