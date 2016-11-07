import util from '../util';

const cookie_name = 'login';
const cookie_config = {
  maxAge: 30 * 24 * 60 * 60 * 1000,
  httpOnly: true
};

// Login: ?login=1
// Logout: ?logout=1
module.exports = function auth(req, res, next) {
  const login = req.body.login || req.query.login;
  const logout = req.body.logout || req.query.logout;
  // mock login user
  if (login === '1') {
    const user_obj = {
      id: 'user0001',
      name: 'Test User',
      team: 'saraban',
      image: util.site_url('http://lorempixel.com/120/120/cats/')
    };
    req.cookies[cookie_name] = user_obj;
    res.cookie(cookie_name, user_obj, cookie_config);
  }

  // mock logout user
  if (logout === '1') {
    res.clearCookie(cookie_name, cookie_config);
    delete req.cookies[cookie_name];
  }

  if (req.cookies[cookie_name]) {
    req.user = res.locals.user = req.cookies[cookie_name];
  }

  // require authenticated user
  if (!req.user) {
    res.redirect('/login');
    return;
  }

  next();
};
