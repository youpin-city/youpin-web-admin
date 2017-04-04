profile-image
  .figure.media.user-media
    .media-left
      figure(class='{ classes }')
        img(if='{ src }', src='{ src }')
        abbr(if='{ !src }', title='{ name }') { initial }
    .media-content(show='{ name || subtitle }')
      .title.is-6 { name }
      .subtitle.is-6(if='{ subtitle }')
        small { subtitle }

  script.
    const self = this;
    self.src = '';
    self.initial = '';
    self.name = '';
    self.subtitle = '';
    self.default_classes = {
      image: true,
      'is-24x24': false,
      'is-48x48': true,
    };

    self.on('before-mount', () => {
      if (self.opts.src) self.src = self.opts.src;
      if (self.opts.name) self.name = self.opts.name;
      if (self.opts.initial) self.initial = _.get(self, 'opts.initial.0', '').toUpperCase();
      else self.initial = _.get(self, 'name.0', '').toUpperCase();
      if (self.opts.subtitle) self.subtitle = self.opts.subtitle;
      //- if (self.opts.size === 'small') {
      if (_.indexOf(self.root.classList, 'is-small') >= 0) {
        self.classes = _.merge(self.default_classes, { 'is-24x24': true, 'is-48x48': false });
      } else {
        self.classes = _.merge(self.default_classes, {});
      }
    });
