/* global app */

import issueRouter from './routes/issue'

const router = module.exports = () => {

    riot.route('/issue-id:*', (id) => {
        issueRouter.process(id);
    });

    riot.route.start();

    Promise.all( [ issueRouter.setup() ] )
      .then( () => {
          setTimeout( () => {
            riot.route.exec();
          }, 1000 );
      });

};
