import _ from 'lodash';
import log from '../logger';
import conf from '../config';
import { APIFetch } from '../api';

export default (req, res, next) => {
  req.api = APIFetch(conf.get('service.api.url'), {}, _.identity);
  next();
};
