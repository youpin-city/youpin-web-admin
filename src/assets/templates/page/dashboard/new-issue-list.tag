dashboard-new-issue-list
  div.new-issue-list.opaque-bg.content-padding
    h1.page-title New issue this week
    ul
      li(each="{item in data}").item
        issue-item(item='{item}', type='compact')

  script.
    let self = this;
    self.data = [];

    api.getNewIssues( (data) => {
      if (data && data.data) self.data = data.data;
      self.update();
    });
