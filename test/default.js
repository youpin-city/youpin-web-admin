// Test helper functions
import { assertTestEnv, expect } from './test_helper';
import conf from '../src/lib/config';
import api from '../src/lib/api';
// App stuff
import app from '../src/lib/app';

// Exit test if NODE_ENV is not equal `test`
assertTestEnv();

describe('Web admin tests', () => {
  let server;
  before((done) => {
    server = app.listen(conf.get('port'));
    server.once('listening', () => done());
  });

  after((done) => {
    server.close(done);
  });

  it('starts and shows the index page', (done) => {
    api.server('/')
    .then(body => {
      expect(body.indexOf('</html>') !== -1).to.be.ok();
      done();
    })
    .catch(err => {
      done(err);
    });
  });
});
