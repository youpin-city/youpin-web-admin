dropdown-menu
  .content
    //- #{'yield'}
    ul.dropdown-list
      li(each='{ item, i in data }')
        a(href='{ item.url }', target='{ item.target }', onclick='{ item.onclick }')
          i.icon(if='{ item.icon }') { item.icon }
          span { item.name }

  script.
    var self = this;
    self._target = opts.target;
    self._content = '.content';
    self.classes = _.compact((opts.class || '').split(' '));
    self.position = 'bottom left';
    self.menu = _.noop;
    self.data = [];

    self.on('before-mount', () => {
      self.setMenu(opts.menu);
      //- if (typeof opts.menu === 'function') {
      //-   self.menu = opts.menu;
      //-   self.setData(self.menu());
      //- }
      if (opts.position) self.position = opts.position;
    });

    self.on('mount', () => {
      self.$target = $(self._target);
      self.target = self.$target.get(0);

      self.$content = $(self.root).find(self._content);
      self.content = self.$content.get(0);

      if (self.target && self.content) {
        self.drop = new Drop({
          target: self.target,
          content: self.content,
          position: self.position,
          classes: ['bb-dropdown'].concat(self.classes).join(' '),
          constrainToWindow: true,
          // constrainToScrollParent: true,
          openOn: 'click',
          remove: 'true',
          tetherOptions: {}
        });
      }
    });

    self.setData = (data) => {
      self.data = _.map(data, item => {
        return _.merge({
          id: _.snakeCase('dd-menu-item-' + util.uniqueId()),
          name: 'Link',
          url: '',
          target: ''
        }, item, {
          onclick: (e) => {
            if (typeof item.onclick === 'function') {
              item.onclick.call(item);
            }
            if (self.drop) {
              self.drop.close();
            }
          }
        });
      })
    }

    self.setMenu = (menu) => {
      if (typeof menu === 'function') {
        self.menu = menu;
        self.setData(self.menu());
      }
    };
