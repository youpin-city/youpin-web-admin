dashboard-new-issue-list
  div.new-issue-list.opaque-bg.content-padding
    h1.page-title New issue this week
    ul
      li(each="{item in data}").item
        issue-item(item='{item}', type='compact')
      //-li(each="{data}").item
        a(href="#!issue-id:{_id}")
          img(src="{photos[0]}")
        span
          a(href="#!issue-id:{_id}")
            b { detail } </br>
          div { _.compact([ created_time, status, assigned_department.name, level ]).join(' / ')  }

  script.
    let self = this;
    self.data = [];

    api.getNewIssues( (data) => {
      if (data && data.data) self.data = data.data;
      self.update();
    });
