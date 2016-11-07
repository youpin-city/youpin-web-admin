import log from '../logger';

export default function hello(data = {}) {
  const str = 'hello! ' + data.me;
  log.debug(str);
  return Promise.resolve(str);
}
