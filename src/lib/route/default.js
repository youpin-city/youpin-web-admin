import pathlib from 'path';
import createError from 'http-errors';
import auth from '../middleware/auth';
import agent from '../agent';
import conf from '../config';
import api from '../api';

// setup
const router = require('express').Router(); // eslint-disable-line
module.exports = router;

router.get('/', auth, (req, res, next) => {
  res.render('dashboard');
});

router.get('/login', (req, res, next) => {
  res.render('login');
});

const cookie_auth_name = 'feathers-jwt';
const cookie_user_info = 'user';
router.get('/logout', (req, res, next) => {
  res.clearCookie(cookie_auth_name);
  delete req.cookies[cookie_auth_name];
  res.clearCookie(cookie_user_info);
  delete req.cookies[cookie_user_info];

  res.redirect('/login');
});

router.get('/auth/success', (req, res, next) => {
  res.redirect('/');
});

function getPins() {
  return api('/pins');
}

router.get('/issue', auth, (req, res, next) => {
  // getPins()
  req.api('/pins')
  .then(result => {
    res.locals.pins = result.data;
    res.render('issue');
  })
  .catch(err => {
    next(err);
  });
});

router.get('/test', auth, (req, res, next) => {
  res.render('test');
});

router.get('/settings/department', auth, (req, res, next) => {
  res.render('settings/department');
});

router.get('/settings/user', auth, (req, res, next) => {
  res.render('settings/user');
});


// all other methods, show not found page
router.all('/*', auth, (req, res, next) => {
  next(createError(404));
});
