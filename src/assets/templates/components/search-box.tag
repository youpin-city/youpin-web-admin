search-box(class='{ open: open }')

  a.toggle-btn(href='#', onclick='{ clickToggleSearch }')
    i.icon.material-icons search

  .search-box-wrapper(name='wrapper')
    form(onsubmit='{ submitSearch }')
      input.flat(type='search', name='q', placeholder='{ placeholder }', onblur='{ clickToggleSearch }', tabindex='-1')

  style(scoped).
    :scope {
      display: inline-block;

      .toggle-btn {
        display: inline-block;
        opacity: 1;
        transition: all 0.2s ease-out;
      }
      .search-box-wrapper {
        display: inline-block;
        width: 0;
        opacity: 0;
        padding-left: 0;
        padding-right: 0;
        transition: all 0.2s ease-out;
      }
      &.open {
        .toggle-btn {
          width: 0;
          opacity: 0;
          padding-left: 0;
          padding-right: 0;
        }
        .search-box-wrapper {
          width: 200px;
          opacity: 1;
          padding-left: 1rem;
          padding-right: 1rem;
        }
      }
    }

  script.
    const self = this;
    self.open = false;
    self.path = opts.path || '';
    self.placeholder = opts.placeholder;


    ////// Render //////
    self.on('updated', function() {
      if (self.open) {
        $(self.q).focus();
        // $(self.wrapper).css('width', '');
      } else {
        // $(self.wrapper).css('width', '70%');
      }
    });

    ////// Action //////
    self.clickToggleSearch = function(e) {
      e.preventDefault();
      self.open = !self.open;
      $('body')[self.open ? 'addClass' : 'removeClass']('global-search-active');
    };

    self.submitSearch = function(e) {
      e.preventDefault();
      location.href = util.site_url(self.path, {
        q: self.q.value
      });
    };
