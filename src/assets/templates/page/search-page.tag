search-page
  div
    h1.page-title Search for "{query}"
  form(action='/', method='get', onsubmit='{doSearch}')
    div.input-field
      input.search-box(type='search', name='keyword', value='{query}')

  div(class="{ hidden: !isNoIssue }")
    h5 No result
  div(class="{ hidden: isNoIssue }")
    h5 Showing {count} results
  div
    issue-list

  script.
    let self = this;

    self.isNoResult = false;

    self.query = opts.q || queryString.parse(location.search).q;

    self.issueList = self.tags['issue-list'];

    function search(keyword) {
      const query = {
        'detail[$regex]': '.*' + keyword + '.*',
        '$sort': '-created_time'
      };
      if (user.role === 'department_head') {
        query.assigned_department = user.department;
      }
      self.tags['issue-list'].load(query);
    }

    self.on('mount', () => {
      search(self.query);
    });

    self.issueList.on('update', () => {
      self.count = self.issueList.pins.length;
      self.isNoIssue = self.count === 0;
      self.update();
    });

    self.doSearch = function(e) {
      e.preventDefault();
      self.query = self.keyword.value;
      search(self.query);
    }