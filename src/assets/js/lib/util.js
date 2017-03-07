/* global app: true */
import urllib from 'url';
import pathlib from 'path';
import _ from 'lodash';
import sanitize_html from 'sanitize-html';

const utility = module.exports;

const hasOwnProperty = Object.prototype.hasOwnProperty;
function extend(...args) {
  const to = args[0];
  let from;
  const copy = function copyValue(key) {
    if (hasOwnProperty.call(from, key)) {
      to[key] = from[key];
    }
  };
  for (let s = 1; s < args.length; s++) {
    from = Object(args[s]);
    Object.keys(from).forEach(copy);
  }
  return to;
}

function item_url(item, prefix = '') {
  return utility.site_url(pathlib.join(prefix, 'item', item.id || item._id));
  // return utility.site_url(pathlib.join(prefix, item._type, item.id || item._id));
}

/**
 * Make slug from string.
 * Support: en, th, ja
 * @see https://gist.github.com/mathewbyrne/1280286
 * @see http://so-zou.jp/software/tech/programming/tech/regular-expression/meta-character/variable-width-encoding.htm
 * @see https://python3.wannaphong.com/2015/12/regular-expression-ภาษาไทย-และภาษาอื่น-python.html
 * @return {String} Slug
 */
const whitespace_like_regex = /[\s_]+/g;
// en: a-z, A-Z, 0-9, -
// th: Ko Kai - Sara Uu, Sara Ee - Thanthakhat, Thai Zero - Thai Nine
//     (Excludes Phintu, Thai Baht, Nikhahit, Yamakkan, Fongman, Angkhankhu, Khomut)
// ja: Kanji, Hiragana, Katakana
const nonword_regex = /[^a-z0-9\-ก-\u0E39เ-\u0E4C๐-๙亜-熙ぁ-んァ-ヶ]+/g;
function slugify(str) {
  return str.toString().toLowerCase()
    .replace(whitespace_like_regex, '-') // Replace spaces with -
    .replace(nonword_regex, '')          // Remove all non-word chars
    .replace(/\-\-+/g, '-')             // Replace multiple - with single -
    .replace(/^-+/, '')                  // Trim - from start of text
    .replace(/-+$/, '');
}

function get_image_intent(params) {
  if (typeof params === 'string') {
    params = utility.IMAGE_INTENT[params] || utility.IMAGE_INTENT.default;
  }
  return params;
}

/**
 *
 * Normalize for flat query string
 * @example
 *   b: 100                   => b=100
 *   a: [1,2,3]               => a[0]=1&a[1]=2&a[2]=3
 *   c: [{d:1,e:2},{d:3,e:4}] => c[0][d]=1&c[0][e]=2&c[1][d]=3&c[1][e]=4
 * @param {Object} query Simple input object
 * @return {Object} Flatten object
 */
function make_querystring(query) {
  const qs = {};
  _.forEach(Object.keys(query), (key) => {
    const value = query[key];
    if (Array.isArray(value)) {
      if (typeof value[0] === 'object') {
        Object.keys(value, (k) => {
          const v = value[k];
          Object.keys(v, (b) => {
            const a = v[b];
            qs[key + '[' + k + '][' + b + ']'] = a;
          });
        });
      } else {
        Object.keys(value, (k) => {
          const v = value[k];
          qs[key + '[' + k + ']'] = v;
        });
      }
    } else {
      qs[key] = value;
    }
  });
  return qs;
}

/**
 * Stringigy querystring object
 * @param  {Object} query Querystring parameters
 * @return {String}       Querystring as string
 */
function format_querystring(query) {
  const qs = [];
  _.forEach(query, (k, v) => {
    if (hasOwnProperty.call(query, k) && query[k]) {
      qs.push(k + '=' + encodeURIComponent(query[k]));
    }
  });
  return qs.join('&');
}

// function format_querystring(params) {
//   return Object.keys(params)
//     .map(k => k + '=' + params[k])
//     .join('&');
// }

function client_size() {
  const w = window;
  const d = document;
  const e = d.documentElement;
  const g = d.getElementsByTagName('body')[0];
  const x = w.innerWidth || e.clientWidth || g.clientWidth;
  const y = w.innerHeight || e.clientHeight || g.clientHeight;
  return { width: x, height: y };
}

function build_image_size(url, breakpoints, dppi, screenWidth, screenBreakpoints) {
  const qs = {};
  let i;
  let b = 0;
  let size;
  let width;
  let height;
  if (breakpoints.length > 0) {
    for (i = 1; i < screenBreakpoints.length; i++) {
      if (screenWidth >= screenBreakpoints[i]) b++;
      else break;
    }
    size = breakpoints[b].split('x');
    width = size[0];
    height = size[1];
    if (width) qs.w = width * dppi;
    if (height) qs.h = height * dppi;
  }
  const q = format_querystring(qs);
  return {
    url: url + (q ? '?' + q : ''),
    width: width,
    height: height
  };
}

function parse_image_url(url) {
  const data = {};
  const split = url ? url.split('#') : [];
  const breakpoints = [];
  let bp = [];
  let i;
  let pt;
  data.url = split[0] || '';
  if (split[1]) {
    bp = (split[1] || '').split('|');
    pt = bp[0];
    for (i = 0; i < 4; i++) {
      pt = (bp[i] || pt);
      breakpoints.push(pt);
    }
  }
  data.breakpoints = breakpoints;
  return data;
}

function site_url(pathname, basepath, query, hash) {
  if (typeof basepath === 'object') {
    hash = query;
    query = basepath;
    basepath = null;
  }
  pathname = pathname || '';
  basepath = basepath || app.get('baseurl');
  query = format_querystring(make_querystring(query || {}));
  query = query ? '?' + query.replace(/^\?/i, '') : '';
  hash = hash ? '#' + hash.replace(/^#/i, '') : '';
  if (/^https?:\/\//.test(pathname)) return pathname;
  return basepath.replace(/\/$/, '') + '/' + pathname.replace(/^\//, '')
    + query + hash;
}

function is_touch_device() {
  return (('ontouchstart' in window)
  || (navigator.MaxTouchPoints > 0)
  || (navigator.msMaxTouchPoints > 0));
}

function device_pixel_ratio() {
  return window.devicePixelRatio || window.screen.availWidth / document.documentElement.clientWidth;
}

function cssSizeInPixel(size, refElement) {
  let rootFontSize;
  let baseFontSize;
  let m;
  let sign;
  let num;
  let unit;
  const cssSizeRegex = /^(-?)([0-9.]*[0-9])([a-z]+)?$/i;
  const matches = cssSizeRegex.exec(size.toString());
  if (matches) {
    refElement = refElement ? $(refElement)[0] : $('html')[0];
    // get root font size in pixel
    rootFontSize = window.getComputedStyle(refElement)['font-size'];
    m = cssSizeRegex.exec(rootFontSize);
    baseFontSize = m ? +m[2] : 10;
    num = matches[1] === '-' ? -matches[2] : +matches[2];
    unit = matches[3];
    if (unit === 'rem') { num = num * baseFontSize; }
    // if (unit === 'em') ...
    // when unit is empty, use how many line-heights
    if (!unit) {
      const lineheight = window.getComputedStyle(refElement)['line-height'];
      const lh = cssSizeRegex.exec(lineheight);
      num = num * +lh[2];
    }
    return num;
  }
  return size;
}

// simple unique ID
function uniqueId() {
  return Math.random().toString(36).substr(2, 9);
}

// Get tag array from string with hashtags
function extract_tags(str) {
  const hash_regex = /\S*#(?:\[[^\]]+\]|\S+)/gi;
  return _.map(((str || '').match(hash_regex) || []).slice(0), tag => tag.slice(1));
}

// Replace hashtags string with link
function parse_tags(str) {
  const hash_regex = /\S*#(\[[^\]]+\]|\S+)/gi;
  return str.replace(hash_regex, '<a href="#tags/$1">#$1</a>');
}

// // Convert class object to string to be used in "class" attributes
// function makeClass(obj) {
//   return _.map(_.filter(_.toPairs(obj), val => val[1]), a => a[0]).join(' ');
// }

extend(utility, {
  // cls: makeClass,
  url: site_url,
  item_url: item_url,
  parseUrl: urllib.parse,
  resolveUrl: urllib.resolve,
  formatUrl: urllib.format,
  make_querystring,
  format_querystring,
  parse_image_url,
  build_image_size,
  client_size,
  site_url,
  is_touch_device,
  device_pixel_ratio,
  cssSizeInPixel,
  uniqueId,
  extract_tags,
  parse_tags,
  sanitize_html,
  strip_tags: html => sanitize_html(html, { allowedTags: [] })
});
