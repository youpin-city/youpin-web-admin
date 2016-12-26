dashboard-recent-activity
  div.recent-activity
    b Recent Activity
    ul
      li(each="{data}").activity
        span
            a(href="#!issue-id:{ pin_id }")
              b { description } </br>
            | { timestamp }


  script.
    let self = this;
    self.data = [];

    api.getRecentActivities( (data) => {
      self.data = _.map( data, d => {
        d.timestamp = moment(d.timestamp).fromNow();
        return d;
      });

      self.update();
    });
