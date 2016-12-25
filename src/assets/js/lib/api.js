/* global app */

import querystring from 'querystring';
import fetch from 'isomorphic-fetch'; // for now

const api = module.exports = {};

const headers = {
    'Authorization': 'Bearer '+ user.token,
    'Content-Type': 'application/json'
};

api._buildEndpoint = function( path, queryParams ){
  return app.config.api_url + "/" + path + '?' + querystring.stringify(queryParams);
};

api.getSummary = ( org, start, end, cb ) => {
  let url = api._buildEndpoint(
    'summaries',
    {
      start_date: start,
      end_date: end,
      organization: org,
      trigger: true
    }
  );

  fetch(url)
    .then(response => response.json())
    .then(cb);

};

api.getNewIssues = (cb) => {
  let opts = {
    '$sort': '-created_time',
    '$limit': 5
  };

  if( user.role !== 'organization_admin' ) {
      opts = _.extend( opts, {
        'assigned_department': user.department
      });
  }

  let url = api._buildEndpoint('pins', opts);

  fetch(url)
    .then(response => response.json())
    .then(cb);

};

api.getRecentActivities = (cb) => {
  let opts = {
    '$sort': '-timestamp',
    '$limit': 10
  };

  if( user.role != 'organization_admin' ) {
      opts = _.extend( opts, {
        'department': user.department
      });
  }

  let url = api._buildEndpoint( 'activity_logs', opts );

  fetch(url)
    .then(response => response.json())
    .then(cb);
}

api.getDepartments = () => {
  let opts = {
    '$limit': 100
  };

  let url = api._buildEndpoint( 'departments', opts );

  return fetch(url).
    then(response => response.json());
}

api.createDepartments = (orgId, deptName) => {
  let body = {
      name: deptName,
      organization: orgId
  };

  let url = api._buildEndpoint('departments');

  return fetch(url, { method: 'POST', body : JSON.stringify(body), headers: headers});
}
