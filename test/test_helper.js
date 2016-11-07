const chai = require('chai');
const sinon = require('sinon');
const dirtyChai = require('dirty-chai');
const sinonChai = require('sinon-chai');

const expect = chai.expect;
const spy = sinon.spy;
const stub = sinon.stub;

chai.use(dirtyChai);
chai.use(sinonChai);

const assertTestEnv = () => {
  // Makes sure that this is actually TEST environment
  if (process.env.NODE_ENV !== 'test') {
    console.log('Woops, you want NODE_ENV=test before you try this again!');
    process.exit(1);
  }
};

module.exports = {
  assertTestEnv,
  expect,
  spy,
  stub,
};
