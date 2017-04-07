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

    self.on('mount', () => {
      self.load();
    });

    self.load = () => {
      const perm_filter = {};
      if (util.check_permission('view_all_issue', user.role)) {
        // no-op
      } else {
        perm_filter.$or = [];
        if (util.check_permission('view_my_issue', user.role)) {
          perm_filter.$or.push({ owner: user._id });
        }
        if (util.check_permission('view_assigned_issue', user.role)) {
          perm_filter.$or.push({ assigned_users: user._id });
        }
        if (util.check_permission('view_department_issue', user.role)) {
          perm_filter.$or.push({ assigned_department: user.dept._id });
        }
        if (perm_filter.$or.length === 0) delete perm_filter.$or;
      }
      const query = _.merge({}, perm_filter, {
        status: {
          $nin: ['resolved', 'rejected']
        },
        $sort: '-created_time',
        $limit: 5
      });

      api.getPins(query)
      .then(data => {
        if (data && data.data) self.data = data.data;
        self.update();
      });
    };
