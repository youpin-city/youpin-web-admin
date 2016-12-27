/* global app $ _ riot util user */

import querystring from 'querystring';
import fetch from 'isomorphic-fetch'; // for now

const api = module.exports = {};

const headers = {
  'Content-Type': 'application/json'
};

if (user && user.token) {
  headers['Authorization'] = 'Bearer '+ user.token;
}

api._buildEndpoint = function( path, queryParams ){
  return app.config.api_url + "/" + path + '?' + querystring.stringify(queryParams);
};

api.getSummary = ( start, end, cb ) => {
  let url = api._buildEndpoint(
    'summarize-states',
    {
      start_date: start,
      end_date: end
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

  // never set assigned_department if department is empty
  if (user.department) {
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

api.createDepartment = (orgId, deptName) => {
  let body = {
      name: deptName,
      organization: orgId
  };

  let url = api._buildEndpoint('departments');

  return fetch(url, { method: 'POST', body : JSON.stringify(body), headers: headers});
}

api.getUsers = () => {
  let opts = {
    '$limit': 100
  };

  let url = api._buildEndpoint( 'users', opts );

  return fetch(url, {headers: headers})
    .then(resp => resp.json());
}

api.createUser = (userObj) => {
  let url = api._buildEndpoint('users');

  return fetch(url, { method: 'POST', body : JSON.stringify(userObj), headers: headers});
}

api.updateUser = (userId, patchObj) => {
  let url = api._buildEndpoint('users/'+userId);
  return fetch(url, { method: 'PATCH', body : JSON.stringify(patchObj), headers: headers});
}

api.getPins = (status, opts) => {

    opts = _.extend({
        '$sort': '-created_time',
        '$limit': 10,
        'status': status
    }, opts );

  let url = api._buildEndpoint( 'pins', opts );

  return fetch(url).then(response => response.json())
}
