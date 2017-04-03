dashboard-recent-activity
  div.recent-activity.opaque-bg.content-padding
    b Recent Activity
    ul
      li(each="{data}").activity
        .activity-item
          collapsible-content(interactive='false', height='4.5rem', default='collapsed')
            a(href="#!issue-id:{ pin_id }")
              .description { description }
          div.meta-time { timestamp }


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
