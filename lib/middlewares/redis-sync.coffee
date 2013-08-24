
redis = require('redis')

class Sync
  constructor: (@_options = {}, @_i18n) ->
    @_options.channel = 'i18n-redis-sync' unless @_options.channel

    @_pub = @_options.pubClient || redis.createClient()
    @_sub = @_options.subClient || redis.createClient()

    @_sub.on 'message', @onMessage
    @_i18n.on 'change', @onChange

    @_sub.subscribe @_options.channel

  onChange: (language, key, value) =>
    @_pub.publish @_options.channel, JSON.stringify(
      language: language
      key: key
      value: value
    )

  onMessage: (channel, message) =>
    resourceChange = JSON.parse(message)
    @_i18n.change(
      resourceChange.language,
      resourceChange.key,
      resourceChange.value,
      false
    )

  dispose: () ->
    @_pub.end()
    @_sub.end()
    @_pub = null
    @_sub = null

module.exports = (options) ->
  (i18n) ->
    sync = new Sync(options, i18n)
    i18n.on 'dispose', ->
      sync.dispose()
      sync = null