search-page
  div(class="{ hidden: !isNoIssue }")
    h1.page-title No result for "{query}"
  div(class="{ hidden: isNoIssue }")
    h1.page-title Search result for "{query}"
    issue-list

  script.
    let self = this;

    self.isNoResult = false;

    self.query = queryString.parse(location.search).q;

    self.issueList = self.tags['issue-list'];

    self.on('mount', () => {
      self.tags['issue-list'].load({
        'detail[$regex]': '.*'+self.query+'.*',
        '$sort': '-created_time',
        'assigned_department': user.department
      });
    });

    self.issueList.on('update', () => {
        self.isNoIssue =  self.issueList.pins.length== 0;
        self.update();
    });
