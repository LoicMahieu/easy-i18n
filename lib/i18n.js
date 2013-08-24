(function() {
  var I18n, events, noop, winston, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  events = require('events');

  winston = require('winston');

  _ = require('lodash');

  noop = function() {};

  I18n = (function(_super) {
    var detection, f, k;

    __extends(I18n, _super);

    I18n.redisSync = require('./middlewares/redis-sync');

    I18n.sequelizeBackend = require('./middlewares/sequelize-backend');

    I18n.loggerConsole = require('./middlewares/logger-console');

    I18n.express = require('./middlewares/express');

    I18n.fallback = require('./middlewares/fallback-translate');

    detection = require('./detection');

    for (k in detection) {
      f = detection[k];
      I18n[k] = f;
    }

    function I18n(options) {
      if (!(this instanceof I18n)) {
        return new I18n(options);
      }
      this.options = _.extend({
        supported_languages: ['fr', 'nl', 'en'],
        default_language: 'fr'
      }, options);
      this.logger = new winston.Logger();
      this.namespaces = {};
    }

    I18n.prototype.use = function(middleware) {
      middleware(this);
      return this;
    };

    I18n.prototype.load = function(language, ns, cb) {
      var _ref,
        _this = this;
      if ((_ref = this.namespaces[ns]) != null ? _ref[language] : void 0) {
        return cb(null);
      }
      if (!this.backend) {
        throw new Error("No backend is provided.");
      }
      this.backend.load(language, ns, function(err, resources) {
        if (err) {
          return cb(err);
        }
        if (!_this.namespaces[ns]) {
          _this.namespaces[ns] = {};
        }
        if (!_this.namespaces[ns][language]) {
          _this.namespaces[ns][language] = {};
        }
        _this.namespaces[ns][language] =  resources;
        _this.emit('nsLoaded', language, ns, resources);
        return cb(null, resources);
      });
      return this;
    };

    I18n.prototype.translate = function(language, ns, key, options) {
      var res, _ref, _ref1;
      if (options == null) {
        options = {};
      }
      if (options.missing !== false) {
        options.missing = true;
      }
      res = (_ref = this.namespaces[ns]) != null ? (_ref1 = _ref[language]) != null ? _ref1[key] : void 0 : void 0;
      if (res) {
        this.emit('translate', language, ns, key, res);
      }
      if (res || !options.missing) {
        return res;
      } else {
        return this.missing(language, ns, key);
      }
    };

    I18n.prototype.missing = function(language, ns, key) {
      this.emit('missing', language, ns, key);
      return language + '/' + ns + ':' + key;
    };

    I18n.prototype.change = function(language, ns, key, value, propagateEvent, cb) {
      var _this = this;
      if (propagateEvent == null) {
        propagateEvent = true;
      }
      if (cb == null) {
        cb = noop;
      }
      if (typeof propagateEvent === 'function') {
        cb = propagateEvent;
        propagateEvent = true;
      }
      this.load(language, ns, function(err) {
        if (err) {
          _this.logger.warn(err);
          return cb(err);
        }
        _this.namespaces[ns][language][key] = value;
        if (propagateEvent) {
          _this.emit('change', language, ns, key, value);
        }
        return cb(null);
      });
      return this;
    };

    I18n.prototype.dispose = function() {
      this.emit('dispose');
      this.backend = null;
      this.resource = null;
      return this.options = null;
    };

    return I18n;

  })(events.EventEmitter);

  module.exports = I18n;

}).call(this);
