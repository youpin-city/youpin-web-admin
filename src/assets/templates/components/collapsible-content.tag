
collapsible-content(id='{ id }')
  .collapsible-wrapper(class='{ collapsed: collapsed }')
    #{'yield'}
    .toggle-expand-btn.hide(onclick='{ toggle }')
    .faux-ellipsis
  footer.align-center(if='{ is_long && !toggle_selector }')
    a.link-text(href='#', onclick='{ toggle }') { collapsed ? expand_label : collapse_label }

  script.
    var self = this;
    self.id = 'collapisble-content-' + util.uniqueId();
    // boolean
    self.is_long = false;
    // is interactive
    self.is_interactive = ['false', false].indexOf(opts.interactive) ? false : true;
    // 'collapsed' 'expanded'
    self.default = opts.default || 'collapsed';
    // string, optional css size unit
    self.height = util.cssSizeInPixel(opts.height || '24rem');
    // external toggle elements (selector)
    self.toggle_selector = opts.toggle || false;
    self.expand_label = opts.expandLabel || 'ดูทั้งหมด';
    self.collapse_label = opts.collapseLabel || 'ย่อขนาด';

    self.on('mount', function() {
      if (self.default === 'collapsed') {
        self.checkNeedCollapsible();
      }
      if (self.toggle_selector) {
        $('body').on('click.' + self.id, self.toggle_selector, function(e) {
          self.toggle(e);
          self.update();
        });
      }
    });

    initCollapsible() {
      var content_height = $(self.root).outerHeight();
      if (content_height > self.height) {
        // collapsed
        self.is_long = true;
        self.makeCollapsed();
      } else {
        // exapanded
        self.is_long = false;
        self.makeExpanded();
      }
      self.update();
    }
    checkNeedCollapsible() {
      setTimeout(self.initCollapsible, 100);
    };

    makeCollapsed() {
      self.collapsed = true;
      $(self.root).find('.collapsible-wrapper')
        .css('max-height', self.height + 'px');
      if (self.toggle_selector) $(self.toggle_selector).text(self.expand_label);
    }
    makeExpanded() {
      self.collapsed = false;
      $(self.root).find('.collapsible-wrapper')
        .css('max-height', '');
      if (self.toggle_selector) $(self.toggle_selector).text(self.collapse_label);
    }

    toggle(e) {
      e.preventDefault();
      self.collapsed = !self.collapsed;
      if (self.collapsed) self.makeCollapsed();
      else self.makeExpanded();
    }
