import conf from './config';
import logger from './logger';
import _ from 'lodash';
import path from 'path';
import express from 'express';
import bodyParser from 'body-parser';
import cookieParser from 'cookie-parser';
import expressValidator from 'express-validator';
import useragent from 'express-useragent';
import i18n, { setFromParams as i18nFromParams } from './i18n';

const app = express();

// Render engine
app.engine('pug', require('pug').__express);
app.set('view engine', 'pug');
app.set('view cache', conf.get('env') === 'production');
app.set('views', path.join(__dirname, '/../assets/views'));
app.set('x-powered-by', false);
if (app.get('env') !== 'production') app.locals.pretty = true;
app.use(require('connect-flash')());

// Configure app
app
  .use(cookieParser())
  .use(bodyParser.json({ limit: '15mb' }))
  .use(bodyParser.urlencoded({ extended: true, limit: '15mb' }))
  .use(expressValidator({}))
  .use(require('serve-favicon')(path.join(__dirname, '../../public/img/favicon/favicon.ico')))
  .use(i18n.init)
  .use(i18nFromParams)
  .use(require('./middleware/security'))
  .use('/public', express.static('public'))
  .use(useragent.express())
  .use(require('./route')(app))
  .use(require('./error-handler'));

// global error handler
process.on('unhandledRejection', (reason, p) => {
  logger.error('Unhandled Rejection at: Promise ', p, ' reason: ', reason);
});

export default app;
