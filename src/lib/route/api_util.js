import _ from 'lodash';
import log from '../logger';
import util from '../util';
import i18n from '../i18n';

function ip(req) {
  return req.headers['x-forwarded-for']
  || req.connection.remoteAddress
  || req.socket.remoteAddress
  || req.connection.socket.remoteAddress;
}

function json_response(res, data) {
  res.set('Content-Type', 'application/json; charset=utf-8');
  res.set('Access-Control-Allow-Origin', '*');
  res.json(data);
  return data;
}

function make_response(res, docs = [], total, page, limit, extension = {}, parser = _.identity) {
  const data = _.assign({
    ok: true,
    pagination: {
      page: page ? page : 1,
      next: page && page < Math.ceil(total / limit) ? page + 1 : false,
      prev: page && page > 1 ? page - 1 : false,
      limit: limit,
      total: total
    },
    data: _.map(docs || [], item => parser(item)),
  }, extension);

  return json_response(res, data);
}

export default {
  ip,
  make_response,
  json_response,
};
