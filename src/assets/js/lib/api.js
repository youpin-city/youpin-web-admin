/* global app $ _ riot util user */

import querystring from 'qs';
import fetch from 'isomorphic-fetch'; // for now
import _ from 'lodash';
import createError from 'http-errors';

const api = module.exports = {};

const headers = {
  'Content-Type': 'application/json'
};

if (user && user.token) {
  headers.Authorization = 'Bearer ' + user.token;
}

function normalize_pin(pin) {
  return _.merge({
    photos: [],
    assigned_department: null,
    assigned_users: [],
    categories: [],
    tags: [],
    comments: [],
    progresses: [],
    merge_children_pins: []
  }, pin);
}

api._buildEndpoint = function (path, queryParams) {
  return app.config.api_url + '/' + path + '?' + querystring.stringify(queryParams);
};

api.getSummary = (start, end, cb) => {
  const url = api._buildEndpoint(
    'summarize-states', {
      start_date: start,
      end_date: end
    }
  );
  return fetch(url).then(response => response.json()).then(cb);
};

api.getRecentActivities = (cb) => {
  let opts = {
    $sort: '-timestamp',
    $limit: 30
  };

  // Admin can see all activities from every department
  if (!util.check_permission('supervisor', user.role)) {
    opts = _.extend(opts, {
      department: user.department
    });
  }

  const url = api._buildEndpoint('activity_logs', opts);
  return fetch(url).then(response => response.json()).then(cb);
};

api.getDepartments = (opts = {}) => {
  const default_opts = {
    $limit: 50
  };
  if (typeof opts === 'object') {
    opts = _.extend(default_opts, opts);
  }

  const url = api._buildEndpoint('departments', opts);
  return fetch(url).then(response => response.json());
};

api.createDepartment = (deptName) => {
  const body = {
    name: deptName,
  };

  const url = api._buildEndpoint('departments');
  return fetch(url, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: headers
  });
};

api.updateDepartment = (deptId, patchObj) => {
  const url = api._buildEndpoint('departments/' + deptId);
  return fetch(url, {
    method: 'PATCH',
    body: JSON.stringify(patchObj),
    headers: headers
  });
};

api.postTransition = (pinId, body) => {
  const url = api._buildEndpoint('pins/' + pinId + '/state_transition');
  return fetch(url, {
    mode: 'cors',
    method: 'POST',
    body: JSON.stringify(body),
    headers: headers
  });
};

api.postPhoto = (formData) => {
  const url = api._buildEndpoint('photos');
  return fetch(url, {
    method: 'POST',
    body: formData
  });
};

api.getUsers = (opts = {}) => {
  const default_opts = {
    $limit: 50
  };
  if (typeof opts === 'object') {
    opts = _.extend(default_opts, opts);
  }

  const url = api._buildEndpoint('users', opts);
  return fetch(url, { mode: 'cors', headers: headers })
  .then(response => response.json());
};

api.createUser = (userObj) => {
  const url = api._buildEndpoint('users');
  return fetch(url, {
    mode: 'cors',
    method: 'POST',
    body: JSON.stringify(userObj), headers: headers
  });
};

api.updateUser = (userId, patchObj) => {
  const url = api._buildEndpoint('users/' + userId);
  return fetch(url, {
    mode: 'cors',
    method: 'PATCH',
    body: JSON.stringify(patchObj), headers: headers
  });
};

api.createPin = (pinObj) => {
  const url = api._buildEndpoint('pins');
  return fetch(url, {
    mode: 'cors',
    method: 'POST',
    body: JSON.stringify(pinObj), headers: headers
  })
  .catch(err => console.log('create pin err:', err))
  .then(response => response.json())
  .then(data => {
    if (data.code >= 400) {
      data.message = data.message + ' ' + _.map(data.errors, 'message').join('\n');
      throw createError(data.code, data);
    }
    return data;
  });
};

api.getPin = (pin_id) => {
  const url = api._buildEndpoint('pins/' + pin_id);
  return fetch(url, { mode: 'cors' })
  .then(response => response.json())
  .then(item => normalize_pin(item));
};

api.getPins = (query) => {
  const queryOpts = _.extend({
    $sort: '-created_time',
    $limit: 20
  }, query);

  const url = api._buildEndpoint('pins', queryOpts);
  return fetch(url, { mode: 'cors' })
  .then(response => response.json());
};

api.patchPin = (pin_id, body) => {
  const url = api._buildEndpoint('pins/' + pin_id);
  return fetch(url, {
    method: 'PATCH',
    body: JSON.stringify(body),
    headers: headers
  });
};

api.mergePins = (child_id, parent_id) => {
  const body = {
    mergedParentPin: parent_id,
  };

  const url = api._buildEndpoint('pins/' + child_id + '/merging');
  return fetch(url, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: headers
  });
};

api.getPinActivities = (pin_id) => {
  const opts = {
    pin_id: pin_id,
    $sort: '-timestamp',
    $limit: 50
  };

  const url = api._buildEndpoint('activity_logs', opts);
  return fetch(url, { mode: 'cors' })
  .then(response => response.json());
};

// 1. {{host}}/pins?updated_time[$gte]=2017-01-09&updated_time[$lte]=2017-01-15&status=resolved
// 2. {{host}}/pins?created_time[$lte]=2017-01-09&status[$in]=pending&status[$in]=assigned&status[$in]=processing
// 3. {{host}}/pins?created_time[$gte]=2017-01-09&created_time[$lte]=2017-01-15&status[$in]=pending&status[$in]=assigned&status[$in]=processing
// api.getPerformance = (input_date, duration = 7, department) => {
api.getPerformance = (start_date, end_date, options = {}) => {
  // const end_date = moment(input_date).add(1, 'days').format('YYYY-MM-DD');
  // const start_date = moment(input_date).subtract(duration, 'days').format('YYYY-MM-DD');
  let current_resolved_pin = 0;
  let current_rejected_pin = 0;
  let current_new_pins = 0;
  let prev_active_pins = 0;
  const queryOpts = {};
  if (options.department) {
    queryOpts.assigned_department = {
      $in: options.department.split(',')
    };
  }
  if (options.user) {
    queryOpts.assigned_users = options.user;
  }
  if (options.category) {
    queryOpts.categories = {
      $in: options.category.split(',')
    };
  }

  // 1. current_resolved_pin
  function get_current_resolved_pin(start_date, end_date, queryOpts) {
    const opts = _.extend(queryOpts, {
      updated_time: {
        $gte: start_date,
        $lte: end_date,
      },
      status: 'resolved'
    });
    const url = api._buildEndpoint('pins', opts);
    return fetch(url).then(response => response.json())
    .then(result => {
      current_resolved_pin = _.get(result, 'total', 0);
      return result;
    });
  }
  // 1. current_rejected_pin
  function get_current_rejected_pin(start_date, end_date, queryOpts) {
    const opts = _.extend(queryOpts, {
      updated_time: {
        $gte: start_date,
        $lte: end_date,
      },
      status: 'rejected'
    });
    const url = api._buildEndpoint('pins', opts);
    return fetch(url).then(response => response.json())
    .then(result => {
      current_rejected_pin = _.get(result, 'total', 0);
      return result;
    });
  }
  // 2. prev_active_pins
  function get_prev_active_pins(start_date, queryOpts) {
    const opts = _.extend(queryOpts, {
      created_time: {
        $lte: start_date,
      },
      status: {
        $in: ['pending', 'assigned', 'processing']
      }
    });
    const url = api._buildEndpoint('pins', opts);
    return fetch(url).then(response => response.json())
    .then(result => {
      prev_active_pins = _.get(result, 'total', 0);
      return result;
    });
  }
  // 3. current_new_pins
  function get_current_new_pins(start_date, end_date, queryOpts) {
    const opts = _.extend(queryOpts, {
      created_time: {
        $gte: start_date,
        $lte: end_date,
      },
      status: {
        $in: ['pending', 'assigned', 'processing']
      }
    });
    const url = api._buildEndpoint('pins', opts);
    return fetch(url).then(response => response.json())
    .then(result => {
      current_new_pins = _.get(result, 'total', 0);
      return result;
    });
  }

  return Promise.resolve({})
  .then(() => get_current_resolved_pin(start_date, end_date, queryOpts))
  .then(() => get_current_rejected_pin(start_date, end_date, queryOpts))
  .then(() => get_prev_active_pins(start_date, queryOpts))
  .then(() => get_current_new_pins(start_date, end_date, queryOpts))
  .then(() => ({
    current_resolved_pin,
    current_rejected_pin,
    prev_active_pins,
    current_new_pins
  }));
};
