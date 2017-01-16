issue-page
  div.bt-new-issue.right
    a.btn(href='#manage-issue-modal') Create New Issue
  h1.page-title
    | Issue
  ul.status-selector
    li(each="{statuses}", class="{active: name == selectedStatus}", onclick="{parent.select(name)}")
      | {name}
      span.badge.new(data-badge-caption='') {totalIssues}

  issue-list

  script.
    let self = this;

    this.statusesForRole = []

    let queryOpts = {};

    if( user.role == 'super_admin' || user.role == 'organization_admin' ) {
      this.statusesForRole =  ['pending', 'assigned', 'processing', 'resolved', 'rejected'];
    } else {
      this.statusesForRole =  ['assigned', 'processing', 'resolved'];
      queryOpts['assigned_department'] = user.department;
    }

    this.statuses = [];
    this.selectedStatus = this.statusesForRole[0];

    function getStatusesCount() {
      Promise.map( self.statusesForRole, status => {
        // get no. issues per status
        let opts = _.extend(
          {},
          queryOpts,
          {
            '$limit': 1,
            is_archived: false,
            status: status
          }
        );

        return api.getPins(opts).then( res => {
          return {
            name: status,
            totalIssues: res.total
          }
        })
      })
      .then( data => {
        self.statuses = data;
        self.update();
        self.select(self.statuses[0].name)();
      });
    }
    getStatusesCount();

    this.select = (status) => {
      return () => {
        self.selectedStatus = status;

        let query = _.extend({
          status: status,
          is_archived: false
        }, queryOpts );

        self.tags['issue-list'].load(query);
      }
    }
