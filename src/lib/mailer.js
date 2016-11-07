import nodemailer from 'nodemailer';
import juice from 'juice'; // inline css and other resoruce for email
import _ from 'lodash';
import Promise from 'bluebird';
import fs from 'fs';
import pathlib from 'path';
import conf from './config';
import log from './logger';

function create_transport(options) {
  let transport;
  switch (options.service) {
    case 'sendgrid':
      // Sendgrid
      transport = require('nodemailer-sendgrid-transport')(options.config);
      transport = nodemailer.createTransport(transport);
      break;
    case 'zoho':
      // Zoho
      transport = require('nodemailer-wellknown')('Zoho');
      transport = nodemailer.createTransport(transport);
      break;
    default:
      // Manual config
      transport = options.config;
      transport = nodemailer.createTransport(transport);
      break;
  }
  if (!transport) throw new Error('No mailer transport created');
  return transport;
}

const mailer = create_transport(conf.get('service.mail_sender'));
const sendMail = Promise.promisify(mailer.sendMail.bind(mailer));
const juiceResources = Promise.promisify(juice.juiceResources.bind(juice));

export default function send(options = {}) {
  const mail_options = {};
  // TEMPLATE => SUBJECT + TEXT + HTML
  if (options.subject) {
    mail_options.subject = options.subject;
  }
  if (options.text) {
    mail_options.text = options.text;
  }
  if (options.html) {
    mail_options.html = options.html;
  }
  if (options.template) {
    const template = conf.get('email_template.' + options.template);
    mail_options.subject = template.subject;
    if (template.text) {
      mail_options.text = template.text;
    }
    if (template.html) {
      mail_options.html = template.html;
    }
  }
  // APPEND FOOTER SIGNATURE
  // INTERPOLATE Variables in TEXT + HTML
  if (mail_options.text) {
    mail_options.text += conf.get('service.mail_sender.signature.footer');
    mail_options.text = _.template(mail_options.text)(options.vars);
  }
  if (mail_options.html) {
    mail_options.html += conf.get('service.mail_sender.signature.footer').replace(/\n/g, '<br/>');
    mail_options.html = _.template(mail_options.html)(options.vars);
  }
  // FROM
  if (options.from) {
    mail_options.from = options.from;
  } else {
    mail_options.from = conf.get('service.mail_sender.signature.from');
  }
  // TO
  mail_options.to = options.to;
  // CC
  mail_options.cc = options.cc;
  // BCC
  mail_options.bcc = options.bcc;

  // Load CSS
  const css_content = fs.readFileSync(
    pathlib.join(conf.get('app_root'), 'public/css/email.css')
  , 'utf8');

  return juiceResources(mail_options.html || '', {
    extraCss: css_content
  })
  .then(html => {
    mail_options.html = html;
    return sendMail(mail_options);
  })
  .then(info => {
    log.info('Email sent.', _.omit(mail_options, ['text', 'html']));
    return info;
  })
  .catch(err => {
    log.error('Email sending failed', err);
    throw err;
  });
}
