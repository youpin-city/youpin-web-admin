import i18n from 'i18n';

const cookie_name = 'lang';
const cookie_config = {
  maxAge: 30 * 24 * 60 * 60 * 1000,
  httpOnly: true
};
const config = {
  locales: ['th', 'en'],
  defaultLocale: 'th',
  cookie: cookie_name,
  queryParameter: cookie_name,
  directory: `${__dirname}/../../config/default/locales`,
  autoReload: false, // true,
  updateFiles: true,
  syncFiles: true,
  indent: '  ',
  objectNotation: true
};

i18n.configure(config);

// Set locale from ?lang=en
export function setFromParams(req, res, next) {
  // set default language if no cookie
  if (!req.cookies[cookie_name]) {
    res.cookie(cookie_name, config.defaultLocale, cookie_config);
    i18n.setLocale(req, config.defaultLocale);
  }
  // set to target lang from querystring
  if (req.query[cookie_name]) {
    res.cookie(cookie_name, req.query[cookie_name], cookie_config);
    i18n.setLocale(req, req.query[cookie_name]);
  }
  next();
}

export default i18n;
