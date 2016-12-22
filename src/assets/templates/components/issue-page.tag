issue-page
  h1.page-title
    | Issue
    div.bt-new-issue
      a.btn(href='#manage-issue-modal') Create New Issue
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
    li.issue.clearfix(each="{ pins }")
      .issue-img
        div.img.responsive-img(style='background-image: url("{ _.get(photos, "0") }");')
        //- img.issue-img(src="http://lorempixel.com/150/150/city/")
      div.issue-body
        div.issue-id
          b ID
          span(href='#manage-issue-modal' data-id='{ _id }') { _id }

          // | 2340984509234
        div.issue-desc { detail }
        //-  | Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source.
        div.issue-category
          div
            b Category
            span.bubble(each="{ cat in categories }") { cat }
          //- span.bubble walkway

        div.issue-location
          div
            b Location
          span.bubble Building A
        div.clearfix

        div.issue-tags
          div
            b Tag
            span.bubble(each="{ tag in tags }") { tag }
          //- span.bubble Walkway
          //- span.bubble Danger
      div.issue-info
        div
          b Status
          span.big-text { status }
          //- span.big-text {selectedStatus}
          div.clearfix

        div
          b Dept.
          span.big-text Engineer
          div.clearfix

        div
          b Thiti Luang

        div Submitted on { moment(created_time).fromNow() }
          //- | [date& time]
        a.bt-manage-issue.btn(href='#manage-issue-modal' data-id='{ _id }') Issue

  script.
    var self = this;
    this.all_pins = opts.pins || [];
    this.pins = this.all_pins;
    this.selectedStatus = 'pending';
    this.statuses = [ { name: 'pending', issues: 4 }, { name: 'assigned', issues: 5 }, { name: 'processing', issues: 2 }, { name: 'resolved', issues: 1 }]

    this.issues = _.range(0, this.statuses[0].issues)

    this.select = function(name){
      return function(){
        self.selectedStatus = name;
        var statusIndex = _.findIndex(self.statuses, { name: name})
        self.issues = _.range(0, self.statuses[statusIndex].issues)
        self.pins = _.filter(self.all_pins, pin => pin.status === name);
        this.update();
      }
    }
