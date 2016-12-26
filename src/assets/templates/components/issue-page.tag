issue-page
  h1.page-title
    | Issue
    div.bt-new-issue
      a.btn(href='#manage-issue-modal') Create New Issue
  ul.status-selector
      li(each="{statuses}", class="{active: name == selectedStatus}", onclick="{parent.select(name)}") {name}({totalIssues})

  div.menu-bar
      div.sorting ▾
      div.list-or-map
          span.active List
          span.separator /
          span Map
      div.clearfix


  ul.issue-list
    li.issue.clearfix(each="{ p in pins }")
      .issue-img
        div.img.responsive-img(style='background-image: url("{ _.get(p.photos, "0") }");')
        //- img.issue-img(src="http://lorempixel.com/150/150/city/")
      div.issue-body
        div.issue-id
          b ID
          span(href='#manage-issue-modal' data-id='{ p._id }') { p._id }
        div.issue-desc { p.detail }
        div.issue-category
          div
            b Category
          span.bubble(each="{ cat in p.categories }") { cat }

        div.issue-location
          div
            b Location
          span.bubble Building A
        div.clearfix

        div.issue-tags
          div
            b Tag
          span.bubble(each="{ tag in p.tags }") { tag }
      div.issue-info
        div
          b Status
        span.big-text { p.status }
        div.clearfix

        div
          b Dept.
        span.big-text Engineer
        div.clearfix

        div(title="assigned to")
          i.icon.material-icons face
          | { p.assigned_user.name }

        div(title="created at")
          i.icon.material-icons access_time
          | { moment(p.created_time).fromNow() }
          //- | [date& time]
        a.bt-manage-issue.btn(href='#manage-issue-modal' data-id='{ p._id }') Issue

    div.load-more-wrapper
      a.load-more(class="{active: hasMore}", onclick="{loadMore()}" ) Load More

  script.
    var self = this;
    this.pins = [];

    // TODO: For super_admin, see all statues

    this.statusesForRole =  ['assigned', 'processing', 'resolved']; // for department worker both head or regular
    this.statuses = []

    this.hasMore = true;

    this.temps = Promise.map( this.statusesForRole, s => {
        // get no. issues per status
        return api.getPins(s, { '$limit': 1 }).then( res => {
            return {
                name: s,
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

        api.getPins(status).then( res => {
          self.pins = res.data;
          console.log(res.data);
          self.updateHasMoreButton(res);
          self.update();
        });
      }
    }

    this.loadMore = () => {
      return () => {
        api.getPins( self.selectedStatus, { '$skip': self.pins.length }).then( res => {
          self.pins = self.pins.concat(res.data)
          self.updateHasMoreButton(res);
          self.update();
        });
      };
    }

    this.updateHasMoreButton = (res) => {
        self.hasMore = ( res.total - ( res.skip + res.data.length ) ) > 0
    }


