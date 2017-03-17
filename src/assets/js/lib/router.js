/* global app riot */

import issueRouter from './routes/issue';
import issueMapRouter from './routes/issue-map';

const router = module.exports = () => {
  riot.route('/issue-id:*', (id) => {
    issueRouter.process(id);
  });

  riot.route('/issue-map:*', (id) => {
    issueMapRouter.process(id);
  });

  riot.route.start();

  setTimeout(function() {
    Promise.all([
      issueRouter.setup(),
      issueMapRouter.setup()
    ])
    .then(() => {
      setTimeout(() => {
        riot.route.exec();
      }, 1000);
    });
  }, 10);
};
