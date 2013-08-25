
var express = require('express');
var http = require('http');
var path = require('path');

function rawBody(req, res, next) {
  req.setEncoding('utf8');
  req.rawBody = '';
  req.on('data', function(chunk) {
    req.rawBody += chunk;
  });
  req.on('end', function(){
    next();
  });
}

require('../setup')(function (i18n, sequelize) {

  var app = express();

  // all environments
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(rawBody);
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser('your secret here'));
  app.use(express.session());
  app.use(i18n.express);
  app.use(app.router);
  app.use(express.static(path.join(__dirname, 'public')));

  // development only
  if ('development' == app.get('env')) {
    app.use(express.errorHandler());
  }

  app.get('/', function (req, res) {
    res.send(req.i18n.translate('home', 'welcome'));
  });

  app.get('/:language/:ns/:key', function (req, res) {
    res.send(req.i18n._i18n.translate(req.params.language, req.params.ns, req.params.key))
  })

  app.get('/:ns/:key', function (req, res) {
    res.send(req.i18n._i18n.translate(req.params.language, req.params.ns, req.params.key))
  })

  app.get('/:key', function (req, res) {
    res.send(req.i18n.translate(req.params.key));
  })

  app.post('/:ns/:key', function (req, res) {
    req.i18n._i18n.change(req.i18n.language, req.params.ns, req.params.key, req.rawBody, function () {
      res.send('ok')
    })
  })

  http.createServer(app).listen(app.get('port'), function(){
    console.log('Express server listening on port ' + app.get('port'));
  });

})