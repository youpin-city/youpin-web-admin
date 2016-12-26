import util from '../util';
import conf from '../config';
import log from '../logger';
import _ from 'lodash';
import { APIFetch } from '../api';

const cookie_auth_name = 'feathers-jwt';
const cookie_user_info = 'user';
const cookie_name = 'login';
const cookie_config = {
  maxAge: 30 * 24 * 60 * 60 * 1000,
  httpOnly: true
};

function parse_jwt(token) {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace('-', '+').replace('_', '/');
    return JSON.parse(new Buffer(base64, 'base64').toString());
  } catch (err) {
    log.error(err);
    return null;
  }
}

module.exports = function auth(req, res, next) {
  const jwt = req.cookies[cookie_auth_name];
  const jwt_data = parse_jwt(jwt);
  const user_id = jwt_data && jwt_data._id;
  if (jwt) {
    const options = {
      headers: {
        Authorization: 'Bearer ' + jwt
      }
    };
    req.api = APIFetch(conf.get('service.api.url'), options, _.identity);
  }

  let get_user;
  if (jwt && user_id) {
    get_user = req.api('/users/' + user_id);
  } else {
    get_user = Promise.resolve(null);
  }

  return get_user
  .then(data => {
    if (data) {
      const user = data;
      user.token = jwt;
      user.department = data.departments[0];
      // assign to user
      req.user = res.locals.user = user;
      req.cookies[cookie_user_info] = user;
      res.cookie(cookie_user_info, user, cookie_config);
    }
  })
  .catch(err => {
    log.error(err);
    res.clearCookie(cookie_auth_name);
    delete req.cookies[cookie_auth_name];
    res.clearCookie(cookie_user_info);
    delete req.cookies[cookie_user_info];
  })
  .then(() => {
    // require authenticated user
    if (!req.user) {
      res.redirect('/login');
      return;
    }

    next();
  });
};
