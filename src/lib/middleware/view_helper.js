import moment from 'moment';
import _ from 'lodash';
import log from '../logger';
import conf from '../config';
import util from '../util';
import md from '../markdown';
import i18n from '../i18n';

module.exports = (req, res, next) => {
  // helper module
  res.locals.settings = conf.get();
  res.locals.util = util;
  res.locals.moment = moment;
  res.locals._ = _;
  res.locals.md = md;

  // helper functions
  res.locals.site_url = util.site_url;
  res.locals.asset_url = util.asset_url;
  res.locals.item_url = util.item_url;

  // default info
  res.locals.page = util.page_info(req, '', req.__('site.fullname'));
  res.locals.sitemap = conf.get('sitemap');
  res.locals.footer_link = conf.get('footer_link');
  res.locals.app_config = {
    env: conf.get('env'),
    version: conf.get('version'),
    baseurl: conf.get('site.host'),
    api_url: conf.get('service.api.url'),
    dict: i18n.locales
  };

  res.locals.user_name = 'Ma Fueng';
  // choose from "super_admin", "organization_admin", "department_admin", "department_worker"
  // res.locals.user_role = 'organization_admin';

  res.locals.user_role = 'department_admin';
  res.locals.user_department = '583b6b63a4918a001117ffa1'; // ID of the deparment

  next();
};
