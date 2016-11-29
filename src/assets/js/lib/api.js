/* global app */

import querystring from 'querystring';
import fetch from 'isomorphic-fetch'; // for now

const api = module.exports = {};

api._buildEndpoint = function( path, queryParams ){
  return app.config.api_url + "/" + path + '?' + querystring.stringify(queryParams);
};

api.getSummary = ( org, start, end, cb ) => {
  let url = api._buildEndpoint(
    'summaries',
    {
      start_date: start,
      end_date: end,
      organization: org
    }
  );

  fetch(url)
    .then(response => response.json())
    .then(cb);

};

api.getNewIssues = (cb) => {
  let url = api._buildEndpoint(
    'pins',
    {
      '$sort': '-created_time',
      '$limit': 5
    }
  );

  fetch(url)
    .then(response => response.json())
    .then(cb);

};
