
module.exports = function harden_server(req, res, next) {
  // CORS
  // @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');

  // X-Frame-Options
  // @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
  res.header('X-Frame-Options', 'DENY');
  // X-Content-Type-Options
  // @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options
  res.header('X-Content-Type-Options', 'nosniff');

  // X-XSS-Protection
  // @see https://wiki.mozilla.org/Security/Guidelines/Web_Security
  res.header('X-XSS-Protection', '1');

  // Sounds good, move on!
  next();
};
