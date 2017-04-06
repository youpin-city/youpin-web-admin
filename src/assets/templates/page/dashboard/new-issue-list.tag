dashboard-new-issue-list
  div.new-issue-list
    h1.page-title New issue this week
    ul
      li(each="{item in data}").item
        issue-item(item='{item}', type='compact')

    .load-more-wrapper.has-text-centered
      a.button.load-more(href='{ util.site_url(\'/issue\') }') Load More

  script.
    let self = this;
    self.data = [];

    api.getNewIssues( (data) => {
      if (data && data.data) self.data = data.data;
      self.update();
    });
