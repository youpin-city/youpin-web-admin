issue-item(class='{ classes }')
  .issue-img
    a.img.responsive-img(href='{ util.site_url("/issue/" + item._id) }', style='background-image: url("{ _.get(item.photos, "0") }");')

  div.issue-body
    div.issue-title
      .is-pulled-right
        .field.is-inline(show='{ ["resolved", "rejected"].indexOf(item.status) >= 0 }')
          .tag.is-small.is-danger ปิดเรื่อง
        .field.is-inline(show='{ item.status === "rejected" }')
          i.icon.material-icons.is-danger { item.closed_reason === 'spam' ? 'bug_report' : 'error_outline' }
        .field.is-inline(show='{ item.status === "resolved" }')
          i.icon.material-icons.is-success check
      a.title.is-plain.is-4(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }') \#{ item._id.slice(-4) }

    div.issue-desc
      a.is-plain(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }') { item.detail }
    div
      ul.tag-list(show='{ item.categories && item.categories.length }')
        li(each='{ cat, i in item.categories }')
          a.tag.is-small.is-primary(href='#{ cat }') { util.t('cat', cat, 'name') }

      .field.is-inline(show='{ Number(item.level) > 0 }')
        .button.is-outlined.is-tiny.is-danger(show='{ item.level >= 3 }') เร่งด่วน
        .button.is-outlined.is-tiny.is-warning(show='{ item.level == 2 }') ปานกลาง
        .button.is-outlined.is-tiny.is-success(show='{ item.level <= 1 }') เล็กน้อย

  .issue-info
    div(show='{ item.assigned_department }') หน่วยงาน { item.assigned_department.name }

    div(show='{ item.assigned_users && item.assigned_users.length }')
      | เจ้าหน้าที่
      .field.is-inline(each='{ staff in item.assigned_users }')
        profile-image.is-round.is-small(title='{ staff.name }', initial='{ staff.name[0].toUpperCase() }')
      .field.is-inline.is-pulled-right(show='{ item.progresses && item.progresses.length }')
        i.icon.material-icons chat_bubble
        span { item.progresses.length }

    div(show='{ item.updated_time }') อัพเดท { moment(item.updated_time).fromNow() }

  .issue-compact
    div.issue-desc
      //- collapsible-content(interactive='false', height='3.6rem', default='collapsed')
      //- a(href='{ util.site_url("/issue/" + item._id) }') { item.detail }
      a.title.is-plain.is-4(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }') \#{ item._id.slice(-4) }
    div.issue-desc
      a.is-plain(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }') { item.detail }
    div
      ul.tag-list(show='{ item.categories && item.categories.length }')
        li(each='{ cat, i in item.categories }')
          a.tag.is-small.is-primary(href='#{ cat }') { util.t('cat', cat, 'name') }

      .field.is-inline(show='{ Number(item.level) > 0 }')
        .button.is-outlined.is-tiny.is-danger(show='{ item.level >= 3 }') เร่งด่วน
        .button.is-outlined.is-tiny.is-warning(show='{ item.level == 2 }') ปานกลาง
        .button.is-outlined.is-tiny.is-success(show='{ item.level <= 1 }') เล็กน้อย
    div(show='{ item.updated_time }') { moment(item.updated_time).fromNow() }

    //- ul.meta-list
    //-   li.meta(title="created at")
    //-     i.icon.material-icons.tiny access_time
    //-     | { moment(item.created_time).fromNow() }

    //-   li.meta
    //-     span.big-text(if='{ item.is_merged }') Merged
    //-     span.big-text(if='{ !item.is_merged }') { _.startCase(item.status) }

    //-   li.meta
    //-     span.text { item.assigned_department ? item.assigned_department.name : '-' }

    //-   li.meta(if='{item.assigned_user_names}', title="assigned to")
    //-     i.icon.material-icons.tiny face
    //-     | { item.assigned_user_names }

  script.
    const self = this;
    self.item = opts.item || {};
    self.classes = {
      issue: true,
      clearfix: true
    };
    self.classes['is-' + self.item.status] = true;
    if (self.opts.type) {
      self.classes['is-' + self.opts.type] = true;
    }
