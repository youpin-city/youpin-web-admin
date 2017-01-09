/* global app $ _ riot util user */

import querystring from 'querystring';
import fetch from 'isomorphic-fetch'; // for now

const api = module.exports = {};

const headers = {
  'Content-Type': 'application/json'
};

if (user && user.token) {
  headers.Authorization = 'Bearer ' + user.token;
}

api._buildEndpoint = function (path, queryParams) {
  return app.config.api_url + '/' + path + '?' + querystring.stringify(queryParams);
};

api.getSummary = (start, end, cb) => {
  const url = api._buildEndpoint(
    'summarize-states',
    {
      start_date: start,
      end_date: end
    }
  );
  fetch(url).then(response => response.json()).then(cb);
};

api.getNewIssues = (cb) => {
  let opts = {
    $sort: '-created_time',
    $limit: 5
  };

  if (!user.is_superuser) {
    if (user.department) {
      // non-admin role can request only his/her department
      opts = _.extend(opts, {
        assigned_department: user.department
      });
    } else {
      // non-admin role cannot request any departments
      opts.$limit = 0;
    }
  }

  const url = api._buildEndpoint('pins', opts);
  fetch(url).then(response => response.json()).then(cb);
};

api.getRecentActivities = (cb) => {
  let opts = {
    $sort: '-timestamp',
    $limit: 10
  };

  if (user.role !== 'organization_admin') {
    opts = _.extend(opts, {
      department: user.department
    });
  }

  const url = api._buildEndpoint('activity_logs', opts);
  fetch(url).then(response => response.json()).then(cb);
};

api.getDepartments = () => {
  const opts = {
    $limit: 100
  };

  const url = api._buildEndpoint('departments', opts);
  return fetch(url).then(response => response.json());
};

api.createDepartment = (deptName) => {
  const body = {
    name: deptName,
  };

  const url = api._buildEndpoint('departments');
  return fetch(url, { method: 'POST', body: JSON.stringify(body), headers: headers });
};

api.updateDepartment = (deptId, patchObj) => {
  const url = api._buildEndpoint('departments/' + deptId);
  return fetch(url, { method: 'PATCH', body: JSON.stringify(patchObj), headers: headers });
};

api.postTransition = (pinId, body) => {
  const url = api._buildEndpoint('pins/' + pinId + '/state_transition');
  return fetch(url, { method: 'POST', body: JSON.stringify(body), headers: headers });
};

api.getUsers = () => {
  const opts = {
    $limit: 100
  };

  const url = api._buildEndpoint('users', opts);
  return fetch(url, { headers: headers }).then(response => response.json());
};

api.createUser = (userObj) => {
  const url = api._buildEndpoint('users');
  return fetch(url, { method: 'POST', body: JSON.stringify(userObj), headers: headers });
};

api.updateUser = (userId, patchObj) => {
  const url = api._buildEndpoint('users/' + userId);
  return fetch(url, { method: 'PATCH', body: JSON.stringify(patchObj), headers: headers });
};

api.getPins = (status, opts) => {
  if (typeof status === 'object') {
    opts = status;
    status = undefined;
  }
  opts = _.extend({
    $sort: '-created_time',
    $limit: 10,
    status: status
  }, opts);

  const url = api._buildEndpoint('pins', opts);
  return fetch(url).then(response => response.json());
};

api.patchPin = (pinId, body) => {
  const url = api._buildEndpoint('pins/' + pinId);
  return fetch(url, { method: 'PATCH', body: JSON.stringify(body), headers: headers });
};
