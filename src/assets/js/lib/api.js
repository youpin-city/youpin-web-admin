/* global app $ _ riot util user */

import querystring from 'qs';
import fetch from 'isomorphic-fetch'; // for now

const api = module.exports = {};

const headers = {
    'Content-Type': 'application/json'
};

if (user && user.token) {
    headers.Authorization = 'Bearer ' + user.token;
}

api._buildEndpoint = function(path, queryParams) {
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
    return fetch(url).then(response => response.json()).then(cb);
};

api.getRecentActivities = (cb) => {
    let opts = {
        $sort: '-timestamp',
        $limit: 10
    };

    // Admin can see all activities from every department
    if (['super_admin', 'organization_admin'].indexOf(user.role) === -1) {
        opts = _.extend(opts, {
            department: user.department
        });
    }

    const url = api._buildEndpoint('activity_logs', opts);
    return fetch(url).then(response => response.json()).then(cb);
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
    return fetch(url, { mode: 'cors', method: 'POST', body: JSON.stringify(body), headers: headers });
};

api.postPhoto = (formData) => {
    const url = api._buildEndpoint('photos');
    return fetch(url, { method: 'POST', body: formData });
};

api.getUsers = (opts) => {
    if (opts === undefined) {
        opts = {
            $limit: 100
        };
    }

    const url = api._buildEndpoint('users', opts);
    return fetch(url, { mode: 'cors', headers: headers }).then(response => response.json());
};

api.createUser = (userObj) => {
    const url = api._buildEndpoint('users');
    return fetch(url, { mode: 'cors', method: 'POST', body: JSON.stringify(userObj), headers: headers });
};

api.updateUser = (userId, patchObj) => {
    const url = api._buildEndpoint('users/' + userId);
    return fetch(url, { mode: 'cors', method: 'PATCH', body: JSON.stringify(patchObj), headers: headers });
};

api.createPin = (pinObj) => {
    const url = api._buildEndpoint('pins');
    return fetch(url, { mode: 'cors', method: 'POST', body: JSON.stringify(pinObj), headers: headers });
};

api.getPin = (pinId) => {
    const url = api._buildEndpoint('pins/' + pinId);
    return fetch(url, { mode: 'cors' }).then(response => response.json());
};

api.getPins = (status, opts) => {
    if (typeof status === 'object') {
        opts = status;
        status = undefined;
    }
    opts = _.extend({
        $sort: '-created_time',
        $limit: 10
    }, opts);

    if (status) opts.status = status;

    const url = api._buildEndpoint('pins', opts);
    return fetch(url, { mode: 'cors' }).then(response => response.json());
};

api.patchPin = (pinId, body) => {
    const url = api._buildEndpoint('pins/' + pinId);
    return fetch(url, { method: 'PATCH', body: JSON.stringify(body), headers: headers });
};

api.mergePins = (child_id, parent_id) => {
    const body = {
        mergedParentPin: parent_id,
    };

    const url = api._buildEndpoint('pins/' + child_id + '/merging');
    return fetch(url, { method: 'POST', body: JSON.stringify(body), headers: headers });
};

// 1. {{host}}/pins?updated_time[$gte]=2017-01-09&updated_time[$lte]=2017-01-15&status=resolved
// 2. {{host}}/pins?created_time[$lte]=2017-01-09&status[$in]=pending&status[$in]=assigned&status[$in]=processing
// 3. {{host}}/pins?created_time[$gte]=2017-01-09&created_time[$lte]=2017-01-15&status[$in]=pending&status[$in]=assigned&status[$in]=processing
// api.getPerformance = (input_date, duration = 7, department) => {
api.getPerformance = (start_date, end_date, department) => {
    // const end_date = moment(input_date).add(1, 'days').format('YYYY-MM-DD');
    // const start_date = moment(input_date).subtract(duration, 'days').format('YYYY-MM-DD');
    let current_resolved_pin = 0;
    let current_new_pins = 0;
    let prev_active_pins = 0;
    let queryOpts = {};
    if (department) {
        queryOpts = {
            assigned_department: {
                $in: department.split(',')
            }
        };
    }

    return Promise.resolve({})
        .then(() => get_current_resolved_pin(start_date, end_date, queryOpts))
        .then(() => get_prev_active_pins(start_date, queryOpts))
        .then(() => get_current_new_pins(start_date, end_date, queryOpts))
        .then(() => {
            return {
                current_resolved_pin,
                prev_active_pins,
                current_new_pins
            };
        });

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
}