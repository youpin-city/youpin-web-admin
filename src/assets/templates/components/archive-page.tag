archive-page
  h1.page-title
    | Archive
  ul.status-selector
    li(each="{statuses}", class="{active: name == selectedStatus}", onclick="{parent.select(name)}")
      | {name}
      span.badge.new(data-badge-caption='') {totalIssues}

  issue-list

  script.
    let self = this;

    this.statusesForRole = []

    let queryOpts = {};

    if( user.role === 'super_admin' || user.role === 'organization_admin' ) {
      this.statusesForRole =  ['resolved', 'rejected'];
    } else {
      this.statusesForRole =  ['resolved'];
      // Non-admins can see only from their department
      // Exception, PR can see all departments
      if (user.role !== 'public_relations') {
        queryOpts['assigned_department'] = user.department;
      }
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
            is_archived: true,
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
          is_archived: true
        }, queryOpts );

        self.tags['issue-list'].load(query);
      }
    }
