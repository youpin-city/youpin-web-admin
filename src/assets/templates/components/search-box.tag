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
        vertical-align: top;
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
          width: 280px;
          opacity: 1;
          padding-left: 1rem;
          padding-right: 1rem;
        }
      }
    }

  script.
    const self = this;
    self.open = false;
    self.path = util.site_url('/search') + '?q=<QUERY>';
    self.placeholder = opts.placeholder;

    let prevQuery = queryString.parse(location.search).q;
    if( prevQuery ) {
      self.open = true;
      $(self.q).val(prevQuery);
      $('body').addClass('global-search-active');
    }

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
      if(self.q.value == '') { return }
      e.preventDefault();

      let url = self.path.replace(/<QUERY>/, self.q.value);
      location.href = url;
    };
