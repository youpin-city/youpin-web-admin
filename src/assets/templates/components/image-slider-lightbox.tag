image-slider-lightbox
  .lightbox-group.columns.is-mobile(ref='group', class='{ "is-highlight": highlight }')
    div(each='{ image, i in data }', class='{ column_classes }')
      a.thumbnail(href='{ image }', target='_blank')
        img(src='{ image }')

  script.
    const self = this;
    self.data = [];
    self.highlight = false;
    self.column = 3;

    self.on('before-mount', () => {
      self.data = self.opts.data;
      self.highlight = !!self.opts.highlight;
      if (self.opts.column) {
        self.column = +self.opts.column;
      }
      self.column_classes = { column: true };
      self.column_classes['is-' + self.column] = true;
    });

    self.on('mount', () => {
      $(self.refs.group).slickLightbox();
    });
