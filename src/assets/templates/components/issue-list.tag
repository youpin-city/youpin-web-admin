issue-list
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
        span.big-text { p.assigned_department ? p.assigned_department.name : '-' }
        div.clearfix

        div(title="assigned to")
          i.icon.material-icons face
          | { p.assigned_user.name }

        div(title="created at")
          i.icon.material-icons access_time
          | { moment(p.created_time).fromNow() }
          //- | [date& time]
        a.bt-manage-issue.btn(href='#!issue-id:{ p._id }') Issue

    div.load-more-wrapper
      a.load-more(class="{active: hasMore}", onclick="{loadMore()}" ) Load More

  script.
    let self = this;
    this.pins = [];

    this.hasMore = true;

    this.load = (opts) => {
        self.currentQueryOpts = opts;

        api.getPins(opts).then( res => {
          self.pins = res.data;
          self.updateHasMoreButton(res);
          self.update();
        });
    }

    this.loadMore = () => {
      return () => {
        let opts = _.extend( {}, self.currentQueryOpts, { '$skip': self.pins.length });
        api.getPins( self.selectedStatus, opts ).then( res => {
          self.pins = self.pins.concat(res.data)
          self.updateHasMoreButton(res);
          self.update();
        });
      };
    }

    this.updateHasMoreButton = (res) => {
        self.hasMore = ( res.total - ( res.skip + res.data.length ) ) > 0
    }
