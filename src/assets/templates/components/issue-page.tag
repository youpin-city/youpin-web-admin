issue-page
  h1.page-title
    | Issue
    div.bt-new-issue
      span Create New Issue
  ul.status-selector
      li(each="{statuses}", class="{active: name == selectedStatus}", onclick="{parent.select(name)}") {name}({issues})

  div.menu-bar
      div.sorting ▾
      div.list-or-map
          span.active List
          span.separator /
          span Map
      div.clearfix
  ul.issue-list
    li.issue(each="{issues}")
      img.issue-img(src="http://lorempixel.com/150/150/city/")
      div.issue-body
        div.issue-id
          b ID
          | 2340984509234
        div.issue-desc
          | Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source.
        div.issue-category
          div
            b Category
          span.bubble walkway

        div.issue-location
          div
            b Location
          span.bubble Building A
        div.clearfix

        div.issue-tags
          div
            b Tag
          span.bubble Walkway
          span.bubble Danger
      div.issue-info
        div
          b Status
          span.big-text {selectedStatus}
          div.clearfix

        div
          b Dept.
          span.big-text Engineer
          div.clearfix

        div
          b Thiti Luang

        div Submitted on [date& time]
        div.bt-manage-issue Manage issue

    script.
      var self = this;
      this.selectedStatus = 'pending';
      this.statuses = [ { name: 'pending', issues: 4 }, { name: 'assigned', issues: 5 }, { name: 'processing', issues: 2 }, { name: 'resolved', issues: 1 }]

      this.issues = _.range(0, this.statuses[0].issues)

      select(name){
        return function(){
          self.selectedStatus = name;
          var statusIndex = _.findIndex(self.statuses, { name: name})
          self.issues = _.range(0, self.statuses[statusIndex].issues)
          this.update();
        }
      }
