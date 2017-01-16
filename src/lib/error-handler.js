import _ from 'lodash';
import conf from './config';
import log from './logger';
import util from './util';

module.exports = (err, req, res, next) => {
  const status = err.status || 500;
  const best = req.accepts(['json', 'html', 'text', 'image', 'video', 'audio']);

  if (err.redirect) {
    res.set('Location', err.redirect);
  }
  if (conf.get('debug')) {
    // log only error status
    if (status >= 400 && status < 600) {
      // omit page not found error
      if (status !== 404) {
        log.error(err);
      }
    }
  }
  res.status(status);
  switch (best) {
    case 'image':
    case 'video':
    case 'audio':
      res.end();
      break;
    case 'html':
      // page nav group
      switch (status) {
        case 401:
          res.locals.page = util.page_info(req, req.url.slice(1), req.__('error.' + status));
          res.render('error/401_unauthorized');
          break;
        case 403:
          res.locals.page = util.page_info(req, req.url.slice(1), req.__('error.' + status));
          res.render('error/403_forbidden');
          break;
        case 404:
          res.locals.page = util.page_info(req, req.url.slice(1), req.__('error.' + status));
          res.render('error/404_notfound');
          break;
        default:
          res.send(
              `<h1>${err.message}</h1>`
            + (conf.get('debug') ? `<h3>${err.code ? 'code: ' + err.code : ''}</h3>` : '')
            + (conf.get('debug') ? `<pre>${_.escape(err.stack)}</pre>` : '')
          );
          break;
      }
      break;
    case 'json':
      res.json({
        ok: false,
        status: status,
        code: err.code,
        message: err.message,
        fields: err.fields
      });
      break;
    default:
      res.send(`${status}: ${err.message}`
        + (conf.get('debug') ? `${err.code ? ' (code: ' + err.code + ')' : ''}` : '')
        + (conf.get('debug') ? err.stack : ''));
  }
};
