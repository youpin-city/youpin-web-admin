import pathlib from 'path';
import createError from 'http-errors';
import auth from '../middleware/auth';
import agent from '../agent';
import conf from '../config';

// setup
const router = require('express').Router(); // eslint-disable-line
module.exports = router;

router.get('/', auth, (req, res, next) => {
  res.render('dashboard');
});

router.get('/login', (req, res, next) => {
  res.render('login');
});

function api(path, method = 'GET', data = {}, options = {}) {
  const method_fn = method.toLowerCase();
  return agent
  .get(conf.get('service.api.url') + path)
  .set({
    // Authorization: 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfaWQiOiI1ODNkZDlkODNkYjIzOTE0NDA3ZjliNGYiLCJpYXQiOjE0ODA0NjE5MzgsImV4cCI6MTQ4MDU0ODMzOCwiaXNzIjoiZmVhdGhlcnMifQ.Jv2173Saxquu-vT6qByScZdLD62btV9A6CodggBBhLA'
  })
  // .send({
  //   email: conf.get('service.api.app_username'),
  //   password: conf.get('service.api.app_password')
  // })
  .then(res => res.body)
  .catch(err => {
    console.error('Failed to get token.', err.body);
    return false;
  });
}

function getPins() {
  return api('/pins');
}

router.get('/issue', auth, (req, res, next) => {
  getPins()
  .then(result => {
    res.locals.pins = result.data;
    res.render('issue');
  })
  .catch(err => {
    next(err);
  });
});

router.get('/test', (req, res, next) => {
  res.render('test');
});

// all other methods, show not found page
router.all('/*', auth, (req, res, next) => {
  next(createError(404));
});
