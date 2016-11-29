dashboard-new-issue-list
  div.new-issue-list
    h1.page-title New issue this week
    ul
      li(each="{data}").item
        img(src="{photos[0]}")
        span
            b { detail } </br>
            | { created_time } / { status } / { assigned_department.name } / { level }


  script.
    let self = this;
    self.data = [];

    api.getNewIssues( (data) => {
      self.data = _.map( data.data, d => {
        d.created_time = moment(d.created_time).fromNow();
        return d;
      });

      self.update();
    });
