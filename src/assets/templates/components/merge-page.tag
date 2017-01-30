merge-page
  div.bt-merge-issue.right
    a.btn(href='#merge-issue-modal', class='{ parent_pin ? "" : "disabled" }', onclick='{ commitMerge }') Merge
  div
    h1.page-title Merge Issues

  .full-container
    .row
      .col.s5
        h5.section-title Merge this issue
        .issue-item.clearfix(if='{ pin }', each="{ p in [pin] }")
          .issue-img
            div.img.responsive-img(style='background-image: url("{ _.get(p.photos, "0") }");')
            //- img.issue-img(src="http://lorempixel.com/150/150/city/")

            div.issue-id
              label ID
              span(href='#manage-issue-modal' data-id='{ p._id }') { p._id.slice(-10) }

          div.issue-body
            div.issue-desc
              //- b Description
              div { p.detail }

            footer
              div.meta.issue-location
                i.icon.material-icons.tiny location_on
                span
                  span.bubble(if='{ p.location_name }') { p.location_name }
              div.meta.issue-category(if='{ p.categories && p.categories.length > 0 }')
                i.icon.material-icons.tiny turned_in_not
                span
                  span.bubble(each="{ cat in p.categories }") { cat }
              div.meta.issue-tags(if='{ p.tags && p.tags.length > 0 }')
                i.icon.material-icons.tiny label
                span
                  span.bubble(each="{ tag in p.tags }") { tag }
          div.issue-info
            div
              label Status
              span.big-text { p.status }

            div
              label Dept.
              span.big-text { p.assigned_department ? p.assigned_department.name : '-' }

            div.meta(if='{p.owner}', title="assigned to")
              i.icon.material-icons.tiny face
              | { p.owner.name }

            div.meta(title="created at")
              i.icon.material-icons.tiny access_time
              | { moment(p.created_time).fromNow() }
              //- | [date& time]
      .col.s1
        div(style='margin-top: 7rem;')
          span.icon.material-icons arrow_forward
      .col.s6
        div(if='{ !parent_pin }')
          h5.section-title Select main issue
        div(if='{ parent_pin }')
          h5.section-title To this issue
          .issue-item.clearfix(each="{ p in [parent_pin] }")
            .issue-img
              div.img.responsive-img(style='background-image: url("{ _.get(p.photos, "0") }");')
              //- img.issue-img(src="http://lorempixel.com/150/150/city/")

              div.issue-id
                label ID
                span(href='#manage-issue-modal' data-id='{ p._id }') { p._id.slice(-10) }

            div.issue-body
              div.issue-desc
                //- b Description
                div { p.detail }

              footer
                div.meta.issue-location
                  i.icon.material-icons.tiny location_on
                  span
                    span.bubble(if='{ p.location_name }') { p.location_name }
                div.meta.issue-category(if='{ p.categories && p.categories.length > 0 }')
                  i.icon.material-icons.tiny turned_in_not
                  span
                    span.bubble(each="{ cat in p.categories }") { cat }
                div.meta.issue-tags(if='{ p.tags && p.tags.length > 0 }')
                  i.icon.material-icons.tiny label
                  span
                    span.bubble(each="{ tag in p.tags }") { tag }
            div.issue-info
              div
                label Status
                span.big-text { p.status }

              div
                label Dept.
                span.big-text { p.assigned_department ? p.assigned_department.name : '-' }

              div.meta(if='{p.owner}', title="assigned to")
                i.icon.material-icons.tiny face
                | { p.owner.name }

              div.meta(title="created at")
                i.icon.material-icons.tiny access_time
                | { moment(p.created_time).fromNow() }
                //- | [date& time]

  .filter-bar.full-container.opaque-bg.content-padding
    .row
      .col.s12
        .section-title Choose an issue to merge
    .row(style='')
      .col.s4
        select(name='sort')
          option(value='-created_time') Newest
          option(value='-updated_time') Most Updated
          option(value='-score') Relevance
      .col.s4
        select(name='department')
          option(each='{ dept in departments }', value='{ dept._id }') { dept.name }
      .col.s4
        form(action='/', method='get', onsubmit='{doSearch}')
          div.input-field
            input.search-box(type='search', name='keyword', value='{query}', placeholder='Search')

  div(class="{ hidden: !isNoIssue }")
    h5 No issue found
  div(class="{ hidden: isNoIssue }")
    h5 Showing {count} issues
  div.parent-issue-list
    merge-issue-list

  script.
    let self = this;
    self.issue_list_tag = 'merge-issue-list';
    self.isNoResult = false;

    self.id = opts.id;

    self.pin = null;
    self.departments = [];
    self.query = opts.q || queryString.parse(location.search).q;

    self.parent_pin_id = null;
    self.parent_pin = null;

    self.issueList = self.tags[self.issue_list_tag];
    self.issueList.on('select-issue', (selected_pin_id) => {
      self.parent_pin_id = selected_pin_id;

      api.getPin(self.parent_pin_id)
      .then(data => {
        self.parent_pin = data;
        self.update();
      });
      // self.update();
    });

    self.on('updated', () => {
      $('select').material_select();
    })

    function loadPin() {
      api.getPin(self.id)
      .then(data => {
        self.pin = data;
        self.update();
      });

      api.getDepartments().then( (res) => {
        self.departments = res.data;
        self.update();
      });
    }

    function search(keyword) {
      const query = {
        'detail[$regex]': '.*' + keyword + '.*',
        '$sort': '-created_time'
      };
      // Admin see all departments
      // if (user.role === 'department_head') {
      //   query.assigned_department = user.department;
      // }
      self.issueList.load(query);
    }

    function nextPins() {
      const query = {
        '$sort': '-created_time'
      };
      // Admin see all departments
      // if (user.role === 'department_head') {
      //   query.assigned_department = user.department;
      // }
      self.issueList.load(query);
    }

    function nextResult() {
      if (!self.query) {
        nextPins();
      } else {
        search(self.query);
      }
    }

    self.on('mount', () => {
      loadPin();
      nextResult();
      // search(self.query);
    });

    self.issueList.on('update', () => {
      self.count = self.issueList.pins.length;
      self.isNoIssue = self.count === 0;
      self.update();
    });

    self.doSearch = function(e) {
      e.preventDefault();
      self.query = self.keyword.value;
      search(self.query);
    };

    self.commitMerge = function(e) {
      e.preventDefault();
      api.mergePins(self.id, self.parent_pin_id)
      .then(response => {
        if (response.ok) {
          location.href = '/issue##!issue-id:' + self.parent_pin_id;
        } else {
          Materialize.toast('Error: ' + resposne.statusText, 8000, 'dialog-error large');
        }
      });
    };
