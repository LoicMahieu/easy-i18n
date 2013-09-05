
class Sync
  constructor: (@_options = {}, @_i18n) ->
    @_options.channel = 'i18n-redis-sync' unless @_options.channel

    @_pub = @_options.pubClient || require('redis').createClient()
    @_sub = @_options.subClient || require('redis').createClient()

    @_sub.on 'message', @onMessage
    @_i18n.on 'modify', @onModify

    @_sub.subscribe @_options.channel

  onModify: (language, namespace, key, value) =>
    message =
      namespace: namespace
      language: language
      key: key
      value: value

    @_i18n.logger.debug(
      "Redis: publish change on channel: #{@_options.channel} with message: ", message
    )
    @_pub.publish @_options.channel, JSON.stringify(message)

  onMessage: (channel, message) =>
    resourceModify = JSON.parse(message)
    @_i18n.logger.debug(
      "Redis: receive change on channel: #{@_options.channel} with message: ", resourceModify
    )
    @_i18n.modify(
      resourceModify.language,
      resourceModify.namespace,
      resourceModify.key,
      resourceModify.value,
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
