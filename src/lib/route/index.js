import pathlib from 'path';
import urllib from 'url';
import conf from '../config';
import api_middleware from '../middleware/api';

// Modify resp.redirect
const resp = require('express').response;
const originalRedirect = resp.redirect;
resp.redirect = function redirect(url) {
  const urlInfo = urllib.parse(url);
  if (!urlInfo.host) url = pathlib.join(this.req.baseUrl, url);
  originalRedirect.call(this, url);
};


// User routes
import default_router from './default';

const router = module.exports = app => {
  // assign frontend middleware
  app.use(require('../middleware/view_helper'));
  app.use(api_middleware);

  // default
  app.use(default_router);

  // show nothing when none of the above routes are enabled
  app.all('/*', (req, res, next) => {
    res.status(404).end();
  });

  return function (req, res, next) { next(); };
};

export default router;
