issue-item(class='{ classes }')
  .issue-select(show='{ is_selectable }')
    .input-field
      input(type='radio', id='select-issue-{ item._id }', name='selected_issue', value='{ item._id }', onchange='{ toggleSelection }')
      label(for='select-issue-{ item._id }')
  .issue-img
    a.img.responsive-image(href='{ util.site_url("/issue/" + item._id) }', riot-style='{ thumbnail_classes }')

  div.issue-body
    div.issue-title
      // closed status
      .is-pulled-right
      a.title.is-plain.is-4(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }')
        .field.is-inline(show='{ item.is_featured }')
          i.icon.material-icons.is-accent star
        span อ { item.issue_id }/60
        .field.is-inline(show='{ ["resolved", "rejected"].indexOf(item.status) >= 0 }')
          .tag.is-small.is-danger ปิดเรื่อง
        .field.is-inline(show='{ item.status === "rejected" }')
          i.icon.material-icons.is-danger { item.closed_reason === 'spam' ? 'delete_forever' : 'error_outline' }
        .field.is-inline(show='{ item.status === "resolved" }')
          i.icon.material-icons.is-success check
        .field.is-inline(show='{ item.is_merged }')
          i.icon.material-icons.is-success content_copy

    div.issue-desc
      a.is-plain(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }') { item.detail }
    div.issue-meta
      ul.tag-list(show='{ item.categories && item.categories.length }')
        li(each='{ cat, i in item.categories }')
          a.tag.is-small.is-primary(href='#{ cat }') { util.t('cat', cat, 'name') }

      .field.is-inline(show='{ Number(item.level) > 0 }')
        .button.is-tiny.is-danger(show='{ item.level >= 3 }') เร่งด่วน
        .button.is-tiny.is-warning(show='{ item.level == 2 }') ปานกลาง
        .button.is-tiny.is-success(show='{ item.level <= 1 }') เล็กน้อย

  .issue-info.is-hidden-mobile
    div(show='{ item.status === "pending" }') ยังไม่รับเรื่อง
    div(show='{ item.assigned_department }') หน่วยงาน 
      span.hilight-text { _.get(item, 'assigned_department.name') }

    div(show='{ item.assigned_users && item.assigned_users.length }')
      | เจ้าหน้าที่
      .field.is-inline(each='{ staff in item.assigned_users }')
        profile-image.is-round.is-small(title='{ staff.name }', initial='{ staff.name[0].toUpperCase() }')
      .field.is-inline.is-pulled-right(show='{ item.progresses && item.progresses.length }')
        i.icon.material-icons chat_bubble
        span { item.progresses.length }

    div(show='{ item.owner }') รายงานโดย 
      span.hilight-text { _.get(item, 'owner.name') }

    div(show='{ item.updated_time }') อัพเดท { moment(item.updated_time).fromNow() }

    div
      ul.issue-timespan(if='{ item.status === "pending" }')
        li.label ส่งเรื่อง
        li.value { total_timespan }

      ul.issue-timespan(if='{ item.status === "assigned" }')
        li.label ส่งเรื่อง
        li.value { total_timespan }
        //- li.label ส่งเรื่อง
        //- li.value { assign_timespan }
        //- li.label รับเรื่อง
        //- li.value { total_timespan }

      ul.issue-timespan(if='{ item.status === "resolved" || item.status === "resolved" }')
        li.label ส่งเรื่อง
        li.value { total_timespan }
        //- li.label ส่งเรื่อง
        //- li.value { assign_timespan }
        //- li.label รับเรื่อง
        //- li.value { total_timespan }
        li.label ปิด

  .issue-compact
    div.issue-title
      // closed status
      .is-pulled-right
        .field.is-inline(show='{ ["resolved", "rejected"].indexOf(item.status) >= 0 }')
          .tag.is-small.is-danger ปิดเรื่อง
        .field.is-inline(show='{ item.status === "rejected" }')
          i.icon.material-icons.is-danger { item.closed_reason === 'spam' ? 'delete_forever' : 'error_outline' }
        .field.is-inline(show='{ item.status === "resolved" }')
          i.icon.material-icons.is-success check
      //- collapsible-content(interactive='false', height='3.6rem', default='collapsed')
      //- a(href='{ util.site_url("/issue/" + item._id) }') { item.detail }
      a.title.is-plain.is-4(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }') อ { item.issue_id }/60
    div.issue-desc
      a.is-plain(href='{ util.site_url("/issue/" + item._id) }' data-id='{ item._id }')
        strong อ { item.issue_id }/60&nbsp;
        | { item.detail }
    div.issue-meta
      ul.tag-list(show='{ item.categories && item.categories.length }')
        li(each='{ cat, i in item.categories }')
          a.tag.is-small.is-primary(href='#{ cat }') { util.t('cat', cat, 'name') }

      //- .field.is-inline(show='{ Number(item.level) > 0 }')
      //-   .button.is-outlined.is-tiny.is-danger(show='{ item.level >= 3 }') เร่งด่วน
      //-   .button.is-outlined.is-tiny.is-warning(show='{ item.level == 2 }') ปานกลาง
      //-   .button.is-outlined.is-tiny.is-success(show='{ item.level <= 1 }') เล็กน้อย
      .field.is-inline(show='{ item.updated_time }') { moment(item.updated_time).fromNow() }

  script.
    const self = this;
    self.item = opts.item || {};
    self.classes = _.merge({
      issue: true,
      clearfix: true
    }, _.fromPairs(self.root.className.split(' ').map(cls => [cls, true])));
    self.is_selectable = self.opts.selectable === 'true';
    if (typeof self.opts.selector === 'function') {
      self.toggleSelection = self.opts.selector;
    } else {
      self.toggleSelection = _.noop;
    }

    // calculate timespan
    if (self.item.resolved_time) {
      self.total_timespan = moment(self.item.assigned_time).from(self.item.resolved_time, true);
    } else if (self.rejected_time) {
      self.total_timespan = moment(self.item.assigned_time).from(self.item.rejected_time, true);
    } else if (self.assigned_time) {
      self.total_timespan = moment(self.item.assigned_time).fromNow(true);
    } else {
      self.total_timespan = moment(self.item.created_time).fromNow(true);
    }
    if (self.item.assigned_time) {
      self.assign_timespan = moment(self.item.created_time).from(self.item.assigned_time, true);
    } else {
      self.assign_timespan = moment(self.item.created_time).fromNow(true);
    }

    // thumbnail class
    self.thumbnail_classes = {};
    if (self.item && self.item.photos && self.item.photos.length > 0) {
      self.thumbnail_classes['background-image'] = `url("${self.item.photos[0]}")`;
    } else {
      self.thumbnail_classes['background-image'] = `url("${util.site_url('/public/img/issue_dummy.png')}")`;
    }
    // status and type classes
    self.classes['is-' + self.item.status] = true;
    if (self.item.is_merged) {
      self.classes['is-merged'] = true;
    }
    if (self.item.merged_children_pins && self.item.merged_children_pins.length > 0) {
      self.classes['is-merged-parent'] = true;
    }
    if (self.opts.type) {
      self.classes['is-' + self.opts.type] = true;
    }
