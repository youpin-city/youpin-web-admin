issue-page
  div.bt-new-issue.right
    a.btn(href='#manage-issue-modal') Create New Issue
  h1.page-title
    | Issue
  ul.status-selector
    li(each="{statuses}", class="{active: name == selectedStatus}", onclick="{parent.select(name)}") {name}({totalIssues})

  issue-list

  script.
    let self = this;

    this.statusesForRole = []

    let queryOpts = {};

    if( user.role == 'super_admin' || user.role == 'organization_admin' ) {
      this.statusesForRole =  ['unverified', 'verified', 'assigned', 'processing', 'resolved', 'rejected'];
    } else {
      this.statusesForRole =  ['assigned', 'processing', 'resolved'];
      queryOpts['assigned_department'] = user.department;
    }

    this.statuses = []

    Promise.map( this.statusesForRole, status => {
        // get no. issues per status
        let opts = _.extend(
          {},
          queryOpts,
          {
             '$limit': 1,
             status: status
          }
        );

        return api.getPins(opts).then( res => {
            return {
                name: status,
                totalIssues: res.total
            }
        })
      }).then( data => {
          self.statuses = data;
          self.update();

          this.select(self.statuses[0].name)();
      });

    this.selectedStatus = this.statusesForRole[0];

    this.select = (status) => {
      return () => {
        self.selectedStatus = status;

        let query = _.extend({
          status: status
        }, queryOpts );

        self.tags['issue-list'].load(query);
      }
    }
