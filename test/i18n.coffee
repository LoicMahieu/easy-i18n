
assert = require 'assert'
should = require 'should'

I18n = require '../index'

describe 'i18n', () ->
  it 'Basic API', (done) ->
    i18n = new I18n()
    
    i18n.should.be.a('object')
    i18n.load.should.be.a('function')
    i18n.translate.should.be.a('function')
    i18n.modify.should.be.a('function')

    done()

  it 'Translate without config return a unified key', (done) ->
    i18n = new I18n()
    i18n.translate('fr', 'namespace', 'key').should.equal('fr/namespace:key')
    done()

  it 'Throw an error if no backend is loaded', (done) ->
    i18n = new I18n()
    assert.throws () -> i18n.load('fr', 'namespace')
    done()

  it 'Can make a basic translate', (done) ->
    i18n = new I18n(
      resources:
        ns:
          en:
            hello: 'Hello world!'
            nodejs: 'Node.js is Awesome!'
          fr:
            hello: 'Bonjour le monde!'
            nodejs: 'Node.js est formidable!'
    )
    i18n.translate('en', 'ns', 'hello').should.equal('Hello world!')
    i18n.translate('fr', 'ns', 'hello').should.equal('Bonjour le monde!')
    i18n.translate('en', 'ns', 'nodejs').should.equal('Node.js is Awesome!')
    i18n.translate('fr', 'ns', 'nodejs').should.equal('Node.js est formidable!')
    done()
