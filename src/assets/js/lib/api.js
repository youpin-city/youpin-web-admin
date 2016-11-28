import querystring from 'querystring';

const api = module.exports = {};

const API_URL = 'http://localhost:3100';

api._buildEndpoint = function( path, queryParams ){
  return API_URL + "/" + path + '?' + querystring.stringify(queryParams);
};

api.getSummary = function( org, start, end, cb ){
  let url = api._buildEndpoint(
    'summaries',
    {
      start_date: start,
      end_date: end,
      organization: org
    }
  );

  $.get(url,cb,'json');
};
