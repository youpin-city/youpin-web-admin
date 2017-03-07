issue-item.issue.clearfix(class='{className}')
  .issue-img
    a.img.responsive-img(href='#!issue-id:{ item._id }', style='background-image: url("{ _.get(item.photos, "0") }");')

    div.issue-id
      label ID
      span(href='#manage-issue-modal' data-id='{ item._id }') { item._id.slice(-10) }

  div.issue-body
    div.issue-desc
      div { item.detail }

    footer
      div.meta.issue-location
        i.icon.material-icons.tiny location_on
        span
          a.bubble(if='{ item.location && item.location.coordinates }', href='#')
            | See map
          span.bubble(if='{ item.location_name }') { item.location_name }
      div.meta.issue-category(if='{ item.categories && item.categories.length > 0 }')
        i.icon.material-icons.tiny turned_in_not
        span
          span.bubble(each="{ cat in item.categories }") { cat }
      div.meta.issue-tags(if='{ item.tags && item.tags.length > 0 }')
        i.icon.material-icons.tiny label
        span
          span.bubble(each="{ tag in item.tags }") { tag }
  .issue-info
    div
      label Status
      span.big-text(if='{ item.is_merged }') Merged
      span.big-text(if='{ !item.is_merged }') { item.status }

    div
      label Dept.
      span.big-text { item.assigned_department ? item.assigned_department.name : '-' }

    div.meta(if='{item.assigned_user_names}', title="assigned to")
      i.icon.material-icons.tiny face
      | { item.assigned_user_names }

    div.meta(title="created at")
      i.icon.material-icons.tiny access_time
      | { moment(item.created_time).fromNow() }
    div
      a.bt-manage-issue.btn.btn-block(href='#!issue-id:{ item._id }') Issue

  .issue-compact
    div.issue-desc
      collapsible-content(interactive='false', height='3.6rem', default='collapsed')
        a(href='#!issue-id:{ item._id }') { item.detail }
    ul.meta-list
      li.meta(title="created at")
        i.icon.material-icons.tiny access_time
        | { moment(item.created_time).fromNow() }

      li.meta
        span.big-text(if='{ item.is_merged }') Merged
        span.big-text(if='{ !item.is_merged }') { _.startCase(item.status) }

      li.meta
        span.text { item.assigned_department ? item.assigned_department.name : '-' }

      li.meta(if='{item.assigned_user_names}', title="assigned to")
        i.icon.material-icons.tiny face
        | { item.assigned_user_names }


  script.
    const self = this;
    self.item = opts.item || {};
    self.className = opts.type ? `is-${opts.type}` : '';
