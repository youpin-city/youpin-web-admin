import pathlib from 'path';
import createError from 'http-errors';
import auth, { reset_user, cookie_auth_name } from '../middleware/auth';
import agent from '../agent';
import conf from '../config';
import log from '../logger';
import util from '../util';

// setup
const router = require('express').Router(); // eslint-disable-line
module.exports = router;

router.get('/', auth(), (req, res, next) => {
  if (req.user.role === 'public_relations') {
    res.redirect('archive');
    return;
  }
  res.render('dashboard');
});

router.get('/login', (req, res, next) => {
  res.locals.success_url = util.site_url('/auth/success');
  res.locals.failure_url = util.site_url('/auth/failure');
  res.render('login');
});

router.get('/logout', (req, res, next) => {
  reset_user(req, res);
  res.redirect('/login');
});

router.get('/auth/success', (req, res, next) => {
  if (req.query.token) {
    res.cookie(cookie_auth_name, req.query.token, conf.get('service.cookie'));
  } else {
    log.error('No token found.');
  }
  res.redirect('/');
});

router.get('/auth/failure', (req, res, next) => {
  res.send('Something went wrong. Try again.');
});

router.get('/issue', auth({ deny: ['public_relations'] }), (req, res, next) => {
  // getPins()
  req.api('/pins')
  .then(result => {
    res.locals.pins = result.data || [];
    res.render('issue');
  })
  .catch(err => {
    next(err);
  });
});

router.get('/archive', auth(), (req, res, next) => {
  res.render('archive');
});

router.get('/search', auth({ deny: ['public_relations'] }), (req, res, next) => {
  res.locals.q = req.query.q;
  res.render('search');
});

router.get('/merge/:id', auth({ deny: ['public_relations'] }), (req, res, next) => {
  res.locals.pin_id = req.params.id;
  res.locals.q = req.query.q;
  res.render('merge');
});

router.get('/settings', auth({ admin: true }), (req, res, next) => {
  res.redirect('settings/user');
});

router.get('/settings/department', auth({ admin: true }), (req, res, next) => {
  res.render('settings/department');
});

router.get('/settings/user', auth({ admin: true }), (req, res, next) => {
  if (['super_admin', 'organization_admin'].indexOf(req.user.role) === -1) {
    next(new createError.Unauthorized());
    return;
  }
  const availableRoles = [
    { id: 'public_relations', name: 'Public Relations' },
    { id: 'department_head', name: 'Department Head' },
    { id: 'organization_admin', name: 'Admin' }
  ];
  if (['super_admin'].indexOf(req.user.role) >= 0) {
    availableRoles.push({ id: 'super_admin', name: 'Super Admin' });
  }
  res.locals.availableRoles = availableRoles;
  res.render('settings/user');
});


// all other methods, show not found page
router.all('/*', (req, res, next) => {
  next(createError(404));
});
