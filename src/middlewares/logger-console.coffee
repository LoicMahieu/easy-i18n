
winston = require 'winston'

module.exports = (options) ->
  (i18n) ->
    i18n.logger.add winston.transports.Console, options
