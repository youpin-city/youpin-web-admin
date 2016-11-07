import schedule from 'node-schedule';
import _ from 'lodash';
import fs from 'fs';
import pathlib from 'path';
import log from './logger';
import conf from './config';

const jobs = [];

function run(rule, job, data, options = {}) {
  // default options
  options.start = options.start || false;
  if (typeof options.enabled === 'undefined') options.enabled = true;

  if (options.start) {
    log.info('run job on start \'' + job._name + '\'');
    job.call(null, data);
  }

  if (options.enabled) {
    log.info('schedule \'' + job._name + '\' at ' + JSON.stringify(rule));
    schedule.scheduleJob(rule, () => {
      log.info('run job \'' + job._name + '\'');
      job.call(null, data);
    });
  }
}

function create_task(job_fn_list) {
  const task = function task(input_data) {
    if (job_fn_list.length === 0) return Promise.resolve(input_data);
    if (job_fn_list.length === 1) return job_fn_list[0].call(null, input_data);
    // use reducer when there're 2 or more jobs
    return Promise.resolve(job_fn_list)
    .mapSeries(job =>
      // pass resolved values from previous to next promise
      job.call(null, input_data)
    )
    .catch(err => {
      log.error('Job halted. Check error above.');
    });
  };
  task._name = _.map(job_fn_list, fn => fn.name).join(' + ');
  return task;
}

function start() {
  const config_jobs = conf.get('cron') || [];
  _.forEach(config_jobs, item => {
    try {
      // const job_module = require(pathlib.join(conf.get('app_root'), 'src/lib/jobs', item.job));
      const job_scripts = _.isArray(item.job) ? item.job : item.job.split(',');
      const job_list = _.map(job_scripts, script_name =>
        require(pathlib.join(conf.get('app_root'), 'src/lib/jobs', script_name)).default
      );

      jobs.push({
        rule: item.rule,
        // job: job_module.default,
        job: create_task(job_list),
        data: item.data,
        options: {
          start: item.start,
          enabled: item.enabled
        }
      });
    } catch (err) {
      log.error(`Failed to load cron job '${item.job}'`, err);
    }
  });

  _.forEach(jobs, job => {
    run(job.rule, job.job, job.data, job.options);
  });
}

function list() {
  return jobs;
}

export default {
  start,
  run,
  list
};
