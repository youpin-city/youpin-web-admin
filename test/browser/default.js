// Test helper functions
import { assertTestEnv, expect } from '../test_helper';
import conf from '../../src/lib/config';
// App stuff
import app from '../../src/lib/app';

// Exit test if NODE_ENV is not equal `test`
assertTestEnv();

describe('First page', () => {
  let server;

  before(() => {
    server = app.listen(conf.get('port'));
    // server.once('listening', () => done());
  });

  after(() => {
    server.close();
    // server.close(done);
  });

  it('should have the right title', () => {
    browser.url('/');
    const title = browser.getTitle();
    expect(title.toLowerCase()).to.contain('icare');
  });
});
