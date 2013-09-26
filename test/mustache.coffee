
assert = require 'assert'
should = require 'should'

I18n = require '../index'

describe 'i18n', () ->
  it 'Can make a basic translate', (done) ->
    i18n = new I18n(
      resources:
        ns:
          en:
            awesome: '{{it}} is awesome!'
            more: '{{sub.value}} be correct'
          fr:
            awesome: '{{it}} est énorme!'
    )
    .use(I18n.mustache())

    i18n.translate('en', 'ns', 'awesome', it: 'Node.js').should.equal('Node.js is awesome!')
    i18n.translate('fr', 'ns', 'awesome', it: 'Node.js').should.equal('Node.js est énorme!')
    i18n.translate('en', 'ns', 'more', sub: value: 'should').should.equal('should be correct')
    done()

  it 'Format missing', (done) ->
    i18n = new I18n()
      .use(I18n.mustache())

    i18n.translate('en', 'ns', 'awesome',
      missing:
        en: 'Its the {{def}}'
      def: 'default'
    ).should.equal('Its the default')

    done()
