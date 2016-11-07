/* eslint no-console: off */
import pathlib from 'path';
import Promise from 'bluebird';

const params = process.argv.slice(2);
const job_name = params[0];

if (!job_name) {
  console.error('No job specified.');
  process.exit();
}

console.log('running job:', job_name);
const job = require(pathlib.join(__dirname, './jobs/', job_name)).default;

job()
.then(result => {
  console.log('all jobs done:', result);
})
.catch(err => {
  console.error('some jobs has failed:', err);
});
