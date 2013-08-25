
module.exports = function (callback) {

  require('source-map-support').install({
    handleUncaughtExceptions: false
  });

  var Sequelize = require('sequelize');

  var I18n = require('../index');

  var sequelize = new Sequelize('test', 'root', '');

  var i18n = I18n({
    })
    .use(I18n.loggerConsole())
    .use(I18n.sequelizeBackend(sequelize))
    .use(I18n.redisSync())
    .use(I18n.express({
      supported_languages: ['en', 'fr', 'nl'],
      default_language: 'en',
      locale_on_url: true,
      redirect_on_missing_on_url: true,
      cookie_name: 'locale',
      preloadNamespaces: ['home'],
      preloadLanguages: ['fr', 'nl']
    }))
    .use(I18n.fallback({
      fallback_language: 'fr'
    }))
  ;

  sequelize.sync({ }).done(function () {
    callback(i18n, sequelize);
  });

}