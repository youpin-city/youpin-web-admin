issue-view-page
  .container
    nav.level.is-mobile
      .level-left.content-padding
        .level-item(show='{ isFeatured() }')
          i.icon.material-icons.is-accent star
        .level-item
          .issue-title.title อ { pin && pin.issue_id }/60
        .level-item(show='{ isClosed() }')
          .tag.is-large.is-danger(title='{  _.startCase(_.get(pin, "closed_reason", "")) }') ปิดเรื่อง
        .level-item(show='{ isClosed() }')
          span(show='{ _.get(pin, "status") === "rejected" }')
            i.icon.material-icons.is-danger { _.get(pin, 'closed_reason') === 'spam' ? 'delete_forever' : 'error_outline' }
          span(show='{ _.get(pin, "status") === "resolved" }')
            i.icon.material-icons.is-success check
          span(show='{ _.get(pin, "is_merged") }')
            i.icon.material-icons.is-success content_copy
          //- span { _.startCase(pin.closed_reason) }
      .level-right.content-padding
        .level-item
          .control
            input(type='text', id='select_priority', ref='select_priority', placeholder='เลือกระดับความสำคัญ')
        .level-item(if='{ pin }')
          a#issue-more-menu-btn(href='#', show='{ show_issue_more_menu_icon }')
            i.icon.material-icons settings
          dropdown-menu(target='#issue-more-menu-btn', position='bottom right', menu='{ action_menu_list }')

    article.message.is-warning(if='{ pin && pin.is_merged }')
      .message-body
        .level.is-mobile
          .level-left
            .level-item
              .title.is-6 เรื่องนี้ถูกตั้งเป็นเรื่องซ้ำซ้อน และรวมอยู่กับเรื่องร้องเรียนหลักนี้
          .level-right
            .level-item
              a(href='/issue/{ parent_pin && parent_pin._id }') ดูเรื่องหลัก
        div(ref='parent_issue')

    .section(if='{ !loaded }')
      //- loading-bar
      .title Loading..
    .section(if='{ loaded }')
      .columns(each='{ pin in [pin] }')
        .column.is-3(hide='{ isEditing("info") }')
          .issue-photos
            div(if='{ !(pin.photos && pin.photos.length) }')
              figure.image.is-square
                img(src='{ default_thumbnail }')
            div(if='{ pin.photos && pin.photos.length }')
              image-slider-lightbox(data='{ pin.photos }', highlight='{ true }')

        .column.is-5(hide='{ isEditing("info") }')
          .issue-view-info
            .issue-detail { pin.detail }
            hr
            .issue-report-detail
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr(show='{ pin.reporter.name }')
                    th ชื่อผู้ร้อง
                    td
                      .field.is-inline { pin.reporter.name }

                  tr(show='{ pin.reporter.line }')
                    th ชื่อ Line
                    td
                      .field.is-inline { pin.reporter.line }

                  //- tr(show='{ pin.owner }')
                  //-   th รายงานโดย
                  //-   td
                  //-     .field.is-inline { pin.owner.name }
                  //-     a#issue-owner-contact-btn.field.is-inline.button.is-tiny(href='#', data-id='{ pin.owner._id }')
                  //-       span ติดต่อกลับ
                  //-     dropdown-menu(ref='owner_contact_menu', target='#issue-owner-contact-btn', position='bottom left')

                  tr(if='{ pin.created_time }')
                    th รายงานเมื่อ
                    td
                      .field.is-inline { moment(pin.created_time).format(app.config.format.datetime_full) }

                  tr
                    th ระยะเวลา
                    td
                      ul.issue-timespan(if='{ pin.status === "pending" }')
                        li.label ส่งเรื่อง
                        li.value { total_timespan }

                      ul.issue-timespan(if='{ pin.status === "assigned" }')
                        li.label ส่งเรื่อง
                        li.value { total_timespan }
                        //- li.label ส่งเรื่อง
                        //- li.value { assign_timespan }
                        //- li.label รับเรื่อง
                        //- li.value { total_timespan }

                      ul.issue-timespan(if='{ pin.status === "resolved" || pin.status === "resolved" }')
                        li.label ส่งเรื่อง
                        li.value { total_timespan }
                        //- li.label ส่งเรื่อง
                        //- li.value { assign_timespan }
                        //- li.label รับเรื่อง
                        //- li.value { total_timespan }
                        li.label ปิด

            hr
            .issue-more-detail
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr
                    th สถานที่
                    td
                      .field.is-inline(show='{ !pin.neighborhood.length && !pin.has_location }') ไม่ระบุ
                      .field.is-inline(show='{ pin.neighborhood && pin.neighborhood.length }') { pin.neighborhood.join(', ') }
                      a#map-view-btn.field.is-inline.button.is-tiny(show='{ pin.has_location }', href='#', data-lat='{ pin.location.coordinates[0] }', data-long='{ pin.location.coordinates[1] }')
                        | ดูบนแผนที่
                      issue-map-modal(show='{ pin.has_location }', data-id='{ id }', name='{ _.get(pin, "neighborhood.0") }', location='{ _.get(pin, "location.coordinates", []).join(",") }', target='#map-view-btn')
                  tr
                    th ประเภท
                    td
                      .field.is-inline(show='{ pin.categories && !pin.categories.length }') -
                      ul.tag-list
                        li(each='{ cat, i in pin.categories }')
                          a.tag.is-small.is-primary(href='#{ cat }') { util.t('cat', cat, 'name') }
                  tr
                    th แท็ก
                    td
                      .field.is-inline(show='{ pin.tags && !pin.tags.length }') -
                      ul.tag-list
                        li(each='{ tag, i in pin.tags }')
                          a.tag.is-small.is-primary(href='#{ tag }') { tag }

                  tr(show='{ pin.owner }')
                    th นำเข้าโดย
                    td
                      .field.is-inline { pin.owner.name }
                      //- a#issue-owner-contact-btn.field.is-inline.button.is-tiny(href='#', data-id='{ pin.owner._id }')
                      //-   span ติดต่อกลับ
                      //- dropdown-menu(ref='owner_contact_menu', target='#issue-owner-contact-btn', position='bottom left')

        #edit-issue-panel.column.is-4(hide='{ isEditing("info") }')
          // assigned department
          .section
            .field
              label.label หน่วยงานรับผิดชอบ
                .is-pulled-right(show='{ util.check_permission("edit_issue_department", user.role) }')
                  a(hide='{ isEditing("department") }', href='#', onclick='{ toggleEdit("department") }')
                    small แก้ไข
                  a(show='{ isEditing("department") }', href='#', onclick='{ toggleEdit("department") }')
                    small ปิด
              .control(hide='{ isEditing("department") }')
                div(show='{ !!pin.assigned_department }')
                  profile-image.is-round-box.is-block(each='{ dept, i in [pin.assigned_department] }', name='{ _.get(dept, "name") }')
                div(hide='{ !!pin.assigned_department }')
                  div ยังไม่มีหน่วยงาน
              .control(show='{ isEditing("department") }')
                input(type='text', id='select_department', ref='select_department', placeholder='เลือกหน่วยงาน')

          //- assigned staff
          .section
            .field
              label.label เจ้าหน้าที่รับผิดชอบ
                .is-pulled-right(show='{ util.check_permission("edit_issue_staff", user.role) }')
                  a(hide='{ isEditing("staff") }', href='#', onclick='{ toggleEdit("staff") }')
                    small แก้ไข
                  a(show='{ isEditing("staff") }', href='#', onclick='{ toggleEdit("staff") }')
                    small ปิด
              .control(hide='{ isEditing("staff") }')
                div(show='{ !!pin.assigned_users.length }')
                  ul.selected-list
                    li(each='{ staff, i in pin.assigned_users }')
                      profile-image.is-round-box.is-block(name='{ _.get(staff, "name") }', subtitle='{ _.get(staff, "department.name") }')
                div(hide='{ !!pin.assigned_users.length }')
                  div ยังไม่มีเจ้าหน้าที่
              .control(show='{ isEditing("staff") }')
                input(type='text', id='select_staff', ref='select_staff', placeholder='เลือกเจ้าหน้าที่')


          //- //- due date
          //- .section
          //-   .field
          //-     label.label กำหนดส่งงาน
          //-     .control
          //-       div
          //-         div ยังไม่มีกำหนดส่งงาน
          //-     .control
          //-       select.select-due-date(ref='select_due_date', placeholder='กำหนดวัน')
          //-         //- option(if='{ !!pin.assigned_department }', value='{ pin.assigned_department._id }', selected) { pin.assigned_department.name }

          //- close issue
          .section(show='{ util.check_permission("close_issue", user.role) }')
            hr
            .action
              button.button.is-outlined.is-accent.is-block(show='{ !isClosed() }', onclick='{ toggleCloseIssueModal }')
                span.text ปิดเรื่อง
              button.button.is-outlined.is-block(show='{ isClosed() }', onclick='{ toggleReopenIssueModal }')
                span.text เปิดเรื่องอีกครั้ง

          //- mark issue as featured on homepage
          //- show when issue is resolved and permission granted
          .section(show='{ pin.status === "resolved" && util.check_permission("mark_featured_issue", user.role) }')
            .action
              button.button.is-outlined.is-accent.is-block(show='{ !isFeatured() }', onclick='{ setIssueAsFeatured }')
                i.icon.material-icons star_border
                span.text จัดแสดงเรื่องนี้
              button.button.is-accent.is-block(show='{ isFeatured() }', onclick='{ unsetIssueAsFeatured }')
                i.icon.material-icons star
                span.text จัดแสดงอยู่


        .column.is-3(show='{ isEditing("info") }')
          .issue-photos
            .field(show='{ update_data.images.length > 0 }')
              .columns.is-wrap
                .column.is-12.is-mobile(each='{ img, i in update_data.images }')
                  figure.image
                    .img-tool
                      button.delete(onclick='{ removeFormPhoto("update_data")(i) }')
                    img(src='{ img }')
            .field
              .control
                form.is-fullwidth(ref='issue_photo_form')
                  label.button.is-accent.is-block(for='issue-photo-input', class='{ "is-loading": saving_info_photo, "is-disabled": saving_info }')
                    i.icon.material-icons add_a_photo
                  input(show='{ false }', id='issue-photo-input', ref='issue_photo_input', type='file', accept='image/*', multiple, onchange='{ chooseFormPhoto("update_data", "issue_photo_form", "saving_info_photo") }')

        .issue-edit-info.column.is-9(show='{ isEditing("info") }')
          .issue-detail
            .field
              label ชื่อผู้ร้อง
              .control
                input.input(type='text', id='reporter_name_input', ref='reporter_name_input', placeholder='', value='{ pin.reporter.name }')
          .issue-detail
            .field
              label ชื่อ LINE ผู้ร้อง
              .control
                input.input(type='text', id='reporter_line_name_input', ref='reporter_line_name_input', placeholder='', value='{ pin.reporter.line }')
          .issue-detail
            .field
              label รายละเอียด
              .control
                textarea.textarea(ref='description_input', placeholder='รายละเอียดปัญหาหรือข้อเสนอแนะที่ถูกรายงานเข้ามา') { pin.detail }
          hr
          .issue-more-detail.columns
            .column.is-6
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr
                    th สถานที่
                    td
                      .field
                        .control
                          input.input(ref='neighborhood_input', type='text', value='{ _.get(pin, "neighborhood.0", "") }', placeholder='จุดสังเกต')
                      .field
                        .control
                          input.input(ref='location_lat_input', type='text', value='{ _.get(pin, "location.coordinates.0", "") }', placeholder='lat')
                      .field
                        .control
                          input.input(ref='location_long_input', type='text', value='{ _.get(pin, "location.coordinates.1", "") }', placeholder='long')
            .column.is-6
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr
                    th ประเภท
                    td
                      .field
                        .control
                          input(type='text', id='select_categories', ref='select_categories', placeholder='เลือกประเภท')
                  tr
                    th แท็ก
                    td
                      .field
                        .control
                          input(type='text', id='select_tags', ref='select_tags', placeholder='เลือกแท็ก')
          hr
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(class='{ "is-disabled": saving_info }', onclick='{ toggleEdit("info") }') ยกเลิก
            .control
              a.button.is-outlined.is-accent(class='{ "is-loading": saving_info }', onclick='{ updateIssueInfo }') บันทึก

    .section(if='{ child_pins && child_pins.length > 0 }')
      .title เรื่องร้องเรียนซ้ำซ้อน
      issue-item.is-compact.is-small.is-plain(each='{ child in child_pins }', item='{ child }')

    #progress-section.section(if='{ loaded }')
      .title ความคืบหน้า
      .progress-list
        // offer new post comment editor
        article.media.progress-item.progress-editor.is-block-mobile(show='{ util.check_permission("post_comment", user.role) }')
          .media-left
            profile-image.is-round.is-block(name='{ user.name }', subtitle='{ user.dept && user.dept.name }')
          .media-content
            .field
              .control
                form(ref='comment_form_detail')
                  textarea.textarea(ref='comment_input', placeholder='แจ้งความคืบหน้า ระบุรายละเอียดงาน')
            .field(show='{ progress_data.images.length > 0 }')
              .columns
                .column.is-3.is-mobile(each='{ img, i in progress_data.images }')
                  figure.image
                    .img-tool
                      button.delete(onclick='{ removeFormPhoto("progress_data")(i) }')
                    img(src='{ img }')
            .field
              .control
                .level
                  .level-left
                    .level-item
                      form.is-fullwidth(ref='comment_photo_form')
                        label.button.is-accent.is-block(for='comment-photo-input', class='{ "is-loading": saving_progress_photo, "is-disabled": saving_progress }')
                          i.icon.material-icons add_a_photo
                        input(show='{ false }', id='comment-photo-input', ref='comment_photo_input', type='file', accept='image/*', multiple, onchange='{ chooseFormPhoto("progress_data", "comment_photo_form", "saving_progress_photo") }')
                  .level-right
                    button.button.is-accent.is-block(class='{ "is-loading": saving_progress, "is-disabled": saving_progress_photo }', onclick='{ submitComment }') ส่งความคืบหน้า
        // previous posts
        article.media.progress-item.is-block-mobile(show='{ util.check_permission("view_comment", user.role) && comments && comments.length > 0 }', each='{ comment, i in comments }')
          .media-left
            profile-image.is-round.is-block(show='{ !!comment.user && comment.type === "comment" }', name='{ comment.user }')
          .media-content
            .content.pre-line.is-marginless
              profile-image.is-round.is-small(show='{ comment.type === "meta" }', initial='{ comment.user }')
              span.break-word(style='padding-left: 0.5rem;') { comment.text }
            div(show='{ comment.annotation }')
              small { comment.annotation }
            .datetime
              small { moment(comment.timestamp).format(app.config.format.datetime_full) }

          .media-right(show='{ comment.photos.length }')
            image-slider-lightbox(data='{ comment.photos }', column='6', highlight='{ false }')

  // Close Issue Modal
  #close-issue-modal.modal.bulma-modal(ref='close_issue_modal', class='{ "is-active": open_modal.close_issue }')
    .modal-background(onclick='{ toggleCloseIssueModal }')
    .modal-card
      header.modal-card-header
        .title ปิดเรื่อง

      section.modal-card-body
        table.table.is-borderless.is-narrow.is-static
          tbody
            tr
              td(style='width: 200px;')
                p ปิดเรื่องร้องเรียน โดยที่
              td
                ul.menu-list
                  li(each='{ item in close_issue_form.type }')
                    a(href='#', data-id='{ item.id }', class='{ "is-active": item.selected }', onclick='{ selectCloseIssueType }')
                      i.icon.material-icons { item.icon }
                      span { item.name }
            tr
              td
                p เหตุผลที่ปิด (ถ้ามี)
              td
                .field
                  .control
                    textarea.textarea(ref='closed_reason_input', placeholder='เช่น เนื่องจากไม่สามารถจัดงบประมาณได้ภายในปีนี้')
      footer.modal-card-footer
        .field.is-grouped.is-pulled-right
          .control
            a.button.is-outlined(class='{ "is-disabled": saving_info }', onclick='{ toggleCloseIssueModal }') ยกเลิก
          .control
            a.button.is-outlined.is-accent(class='{ "is-loading": saving_info }', onclick='{ commitCloseIssue }') ยืนยันปิดเรื่อง

  // Reopen Issue Modal
  #reopen-issue-modal.modal.bulma-modal(ref='reopen_issue_modal', class='{ "is-active": open_modal.reopen_issue }')
    .modal-background(onclick='{ toggleReopenIssueModal }')
    .modal-card
      header.modal-card-header
        .title เปิดเรื่องใหม่

      section.modal-card-body
        p คุณสามารถเปิดเรื่องที่ปิดไปแล้วได้อีกครั้ง เพื่อดำเนินการแก้ไขปัญหาให้สำเร็จ
      footer.modal-card-footer
        .field.is-grouped.is-pulled-right
          .control
            a.button.is-outlined(class='{ "is-disabled": saving_info }', onclick='{ toggleReopenIssueModal }') ยกเลิก
          .control
            a.button.is-outlined.is-accent(class='{ "is-loading": saving_info }', onclick='{ commitReopenIssue }') ยืนยันเปิดเรื่องใหม่

  script.
    const self = this;
    self.default_thumbnail = util.site_url('/public/img/issue_dummy.png');
    self.loaded = false;
    self.pin = null;
    self.parent_pin = null;
    self.child_pins = [];
    // pin info
    self.update_data = { photos: [], images: [] };
    self.editing_info = false;
    self.saving_info = false;
    self.saving_info_photo = false;
    self.editing_department = false;
    self.editing_staff = false;
    // comment
    self.activities = [];
    self.comments = [];
    self.saving_progress = false;
    self.saving_progress_photo = false;
    self.progress_data = { photos: [], images: [], detail: '' };


    self.open_modal = {
      close_issue: false,
      reopen_issue: false
    };

    self.show_issue_more_menu_icon = false;
    self.action_menu_list = () => {
      const menu = [];
      // create new issue
      if (util.check_permission('edit_issue', user.role)) {
        menu.push({
          id: 'edit-issue-btn',
          name: 'แก้ไขข้อมูล',
          url: '#',
          target: '',
          onclick: (e) => { self.toggleEdit('info')(); }
        });
      }
      // mark this issue as duplicate
      if (self.pin && !self.pin.is_merged
        && util.check_permission('merge_issue', user.role)) {
        menu.push({
          id: 'merge-issue-btn',
          name: 'แจ้งเรื่องซ้ำซ้อน',
          url: util.site_url('/merge/') + self.id
        });
      }
      if (menu.length > 0) {
        self.show_issue_more_menu_icon = true;
      }
      return menu;
    };

    self.close_issue_form = {
      type: [
        { id: 'resolved', value: 'resolved', name: 'แก้ไขเรื่องร้องเรียนเสร็จแล้ว', icon: 'check_circle', selected: true },
        { id: 'rejected', value: 'rejected', name: 'ไม่สามารถแก้ไขเรื่องร้องเรียนนี้', icon: 'remove_circle' },
        { id: 'spam', value: 'rejected', name: 'เป็นสแปมหรือแจ้งเหตุไม่เหมาะสม', icon: 'bug_report' }
      ]
    };

    self.on('before-mount', () => {
      self.id = self.opts.dataId;
    });

    self.on('mount', () => {
      self.loadPin();
      self.bindEvents();
    })

    self.on('before-unmount', () => {
      self.unbindEvents();
    })

    self.on('update', (data) => {
      self.calculateComments();
    });

    self.isEditing = (prop) => self['editing_' + prop];

    self.toggleEdit = (prop) => (e) => {
      //- if (e && e.preventDefault) e.preventDefault();
      self['editing_' + prop] = !self['editing_' + prop];
      self.update();
    }

    self.isClosed = () => {
      return self.pin && self.pin.status
        && ["resolved", "rejected"].indexOf(self.pin.status) >= 0;
    };

    self.isFeatured = () => {
      return self.pin && self.pin.is_featured;
    };

    self.parseIssue = (pin) => {
      pin.neighborhood = _.compact(pin.neighborhood);
      if (!pin.location || !pin.location.coordinates
        || (pin.location.coordinates[0] === 0 && pin.location.coordinates[1] === 0)) {
        pin.has_location = false;
      } else {
        pin.has_location = true;
      }

      // calculate timespan
      if (pin.resolved_time) {
        self.total_timespan = moment(pin.assigned_time).from(pin.resolved_time, true);
      } else if (self.rejected_time) {
        self.total_timespan = moment(pin.assigned_time).from(pin.rejected_time, true);
      } else if (self.assigned_time) {
        self.total_timespan = moment(pin.assigned_time).fromNow(true);
      } else {
        self.total_timespan = moment(pin.created_time).fromNow(true);
      }
      if (pin.assigned_time) {
        self.assign_timespan = moment(pin.created_time).from(pin.assigned_time, true);
      } else {
        self.assign_timespan = moment(pin.created_time).fromNow(true);
      }
      return pin;
    };

    self.loadPin = () => {
      return api.getPin(self.id)
      .then(data => {
        self.loaded = true;
        self.pin = self.parseIssue(data);
        self.update_data.photos = _.clone(self.pin.photos);
        self.update_data.images = _.clone(self.pin.photos);
        self.update();

        self.initSelectDepartment();
        self.initSelectStaff();
        self.initSelectCategory();
        self.initSelectTag();
        self.initSelectPriority();
        self.loadPinActivities();

        // if this has parent pin (a.k.a. this pin is a duplicate)
        if (self.pin.is_merged) {
          api.getPin(self.pin.merged_parent_pin)
          .then(data => {
            self.parent_pin = self.parseIssue(data);
            riot.mount(self.refs.parent_issue, 'issue-item', { item: self.parent_pin });
            self.update();
          });
        }
        // if this has child pins
        if ((self.pin.merged_children_pins || []).length > 0) {
          api.getPins({ merged_parent_pin: self.pin._id })
          .then(data => {
            self.child_pins = data.data;
            self.update();
          });
        }

        // contact menu
        if (self.refs.owner_contact_menu && self.pin.owner) {
          self.refs.owner_contact_menu.setMenu(() => [
            {
              id: 'contact-owner-email-btn',
              name: 'Email: ' + self.pin.owner.email,
              url: `mailto:${self.pin.owner.email}?subject=[iCare #${self.id.slice(-4)}] ${self.pin.detail}`,
              target: ''
            }
          ]);
        }

        return data;
      });
    }

    self.loadPinActivities = () => {
      api.getPinActivities(self.id)
      .then(data => {
        self.activities = data;
        self.update();
      });
    }

    self.initSelectDepartment = () => {
      //- value='{ _.get(pin, "assigned_department._id") }', selected) { _.get(pin, "assigned_department.name") }
      const assigned_dept = self.pin.assigned_department ? {
        _id: _.get(self, 'pin.assigned_department._id'),
        name: _.get(self, 'pin.assigned_department.name')
      } : null;
      $(self.refs.select_department).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        searchField: 'name',
        options: _.compact([assigned_dept]), // all choices
        items: assigned_dept ? [assigned_dept._id] : [], // selected choices
        create: false,
        hideSelected: true,
        preload: true,
        onDropdownOpen: function($dropdown) {
          $dropdown.find('profile-image').each((i, el) => {
            if (!el._tag) { riot.mount(el, 'profile-image'); }
          })
        },
        render: {
          option: function(item, escape) {
            var name = item.name || '';
            return '<profile-image class="is-round-box is-small is-block" name="' + escape(name) + '"></profile-image>';
          }
        },
        load: function(query, callback) {
          //- if (!query.length) return callback();
          let opts;
          if (util.check_permission('view_department', user && user.role)) {
            opts = {};
          } else {
            opts = { _id: _.get(user, 'dept._id') };
          }

          api.getDepartments(opts)
          .then(result => {
            callback(result.data);
          });
        },
        onChange: function(value) {
          const update = value ? { assigned_department: value }
            : { assigned_department: null };
          // force state change to assigned
          // when assign department for the first time
          // (when it's still 'pending')
          const should_change_state = !!value && self.pin.status === 'pending';
          if (should_change_state) {
            update.state = 'assigned';
          }

          (should_change_state
          ? api.postTransition(self.id, update)
          : api.patchPin(self.id, update))
          .catch(err =>
            Materialize.toast(err.message, 8000, 'dialog-error large')
          )
          .then(() => self.loadPin());
        }
      });
    }

    self.initSelectStaff = () => {
      const staff_list = self.pin.assigned_users
      const select = self.refs.select_staff;
      $(select).selectize({
        valueField: '_id',
        labelField: 'name',
        searchField: 'name',
        options: staff_list, // all choices
        items: _.map(staff_list, '_id'), // selected choices
        create: false,
        //- hideSelected: true,
        preload: true,
        onDropdownOpen: function($dropdown) {
          $dropdown.find('profile-image').each((i, el) => {
            if (!el._tag) { riot.mount(el, 'profile-image'); }
          })
        },
        render: {
          option: function(item, escape) {
            var name = item.name || item.email;
            var department = item.department ? item.department.name : 'ไม่มีหน่วยงาน';
            return '<profile-image class="is-round is-small is-block" name="' + escape(name) + '" subtitle="' + escape(department) + '"></profile-image>';
          }
        },
        load: function(query, callback) {
          //- if (!query.length) return callback();
          let opts;
          if (util.check_permission('view_all_staff', user && user.role)) {
            opts = {};
          } else if (util.check_permission('view_department_staff', user && user.role)) {
            opts = { department: _.get(user, 'dept._id') };
          }
          if (!opts) return;

          api.getUsers(opts)
          .then(result => {
            callback(result.data);
          });
        },
        onItemAdd: function(value, $item) {
          api.patchPin(self.id, {
            $push: { assigned_users: value }
          })
          .catch(err =>
            Materialize.toast(err.message, 8000, 'dialog-error large')
          )
          .then(response => self.loadPin());
        },
        onItemRemove: function(value) {
          const staff_ids = _.filter(self.pin.assigned_users, user => user._id !== value)
            .map(user => user._id);
          api.patchPin(self.id, { assigned_users: staff_ids })
          .catch(err =>
            Materialize.toast(err.message, 8000, 'dialog-error large')
          )
          .then(response => self.loadPin());
        }
      });
    }

    self.initSelectCategory = () => {
      const select = $(self.root).find('#select_categories').get(0); //self.refs.select_tags;
      const cat_list = app.get('issue.categories') || [];
      const selected_cat_list = self.pin.categories || [];
      $(select).selectize({
        maxItems: 3,
        valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        options: cat_list, // all choices
        items: selected_cat_list, // selected choices
        create: false
      });
    }

    self.initSelectTag = () => {
      const select = $(self.root).find('#select_tags').get(0); //self.refs.select_tags;
      const tag_list = self.pin.tags.map(tag => ({ id: tag, name: tag }));
      $(select).selectize({
        valueField: 'id',
        labelField: 'name',
        options: tag_list, // all choices
        items: _.map(tag_list, 'id'), // selected choices
        create: true,
        render: {
          option_create: function(data, escape) {
            return '<div class="create">เพิ่ม <strong>' + escape(data.input) + '</strong></div>';
          }
        }
      });
    }

    self.initSelectPriority = () => {
      const priority = [
        { id: '1', name: 'เล็กน้อย' },
        { id: '2', name: 'ปานกลาง' },
        { id: '3', name: 'เร่งด่วน' },
      ];
      $(self.refs.select_priority).selectize({
        maxItems: 1,
        valueField: 'id',
        labelField: 'name',
        //- searchField: 'name',
        options: _.compact(priority), // all choices
        items: self.pin.level ? [self.pin.level] : ['2'], // selected choices
        create: false,
        allowEmptyOption: false,
        //- hideSelected: true,
        //- preload: true,
        onChange: function(value) {
          const update = value ? { level: value }
            : { level: 2 };
          api.patchPin(self.id, update)
          .catch(err =>
            Materialize.toast(err.message, 8000, 'dialog-error large')
          )
          .then(response => self.loadPin());
        }
      });
    }

    self.chooseFormPhoto = (group_name = '', form_ref = '', uploading_flag = '') => (e) => {
      if (!group_name) return Promise.reject(false);
      const file_input = e.currentTarget;
      if (!(window.FileList && file_input && file_input.files instanceof window.FileList)) {
        return Promise.resolve([]);
      }
      if (uploading_flag) self[uploading_flag] = true;
      //- self.saving_progress_photo = true;
      return Promise.resolve(_.toArray(file_input.files))
      .map(file => {
        const photo_blob_url = window.URL.createObjectURL(file);
        return fetch(photo_blob_url)
        .then(response => response.blob())
        .then(blob => {
          const form = new FormData();
          form.append('image', blob);
          return api.postPhoto(form);
        })
        .then(response => response.json())
        .then(photo_data => {
          self[group_name].photos.push(photo_data.url);
          self[group_name].images.push(photo_blob_url);
          return photo_data.url;
        })
        .catch(err =>
          Materialize.toast(err.message, 8000, 'dialog-error large')
        )
      })
      .then(result => {
        if (form_ref && self.refs[form_ref]) self.refs[form_ref].reset();
        if (uploading_flag) self[uploading_flag] = false;
        self.update();
      });
    };

    self.removeFormPhoto = (group_name ='') => (index) => (e) => {
      if (!group_name) return;
      self[group_name].photos.splice(index, 1);
      self[group_name].images.splice(index, 1);
      self.update();
    };

    self.submitComment = (e) => {
      if (e && e.preventDefault) e.preventDefault();
      //- const files = self.refs.comment_photo_input.files;
      //- self.progress_data.photos = _.map(files || [], file => window.URL.createObjectURL(file));
      self.progress_data.detail = self.refs.comment_input.value;
      if (!self.progress_data.detail) {
        Materialize.toast('พิมพ์ข้อความอธิบาย เพื่อส่งความคืบหน้า', 8000, 'large')
        return;
      }

      // upload photo first, if any
      self.saving_progress = true;
      return api.patchPin(self.id, {
        $push: {
          progresses: {
            detail: self.progress_data.detail,
            photos: self.progress_data.photos,
            owner: user._id
          }
        }
      })
      .then(response => {
        self.refs.comment_form_detail.reset();
        self.refs.comment_photo_form.reset();
        self.progress_data.photos = [];
        self.progress_data.images = [];
        self.progress_data.detail = '';
      })
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      )
      .then(() => {
        self.saving_progress = false;
        self.update();
        self.loadPin()
      });
    }

    self.updateIssueInfo = (e) => {
      const update = {
        detail: self.refs.description_input.value,
        photos: self.update_data.photos,
        neighborhood: _.compact([self.refs.neighborhood_input.value]),
        'location.coordinates': [
          self.refs.location_long_input.value,
          self.refs.location_lat_input.value
        ],
        categories: _.compact(self.refs.select_categories.value.split(',')).map(cat => _.trim(cat)),
        tags: _.compact(self.refs.select_tags.value.split(',')).map(tag => _.trim(tag)),
        reporter: {
          name: self.refs.reporter_name_input.value,
          line: self.refs.reporter_line_name_input.value
        }
      }
      self.saving_info = true;
      api.patchPin(self.id, update)
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      )
      .then(response => self.loadPin())
      .then(() => {
        self.saving_info = false;
        self.toggleEdit('info')();
      });
    };

    self.bindEvents = () => {
      $(self.root).on('click.dd', '#edit-issue-btn', (e) => {
        self.toggleEdit('info');
      });
    };

    self.unbindEvents = () => {
      $(self.root).off('click.dd', '#edit-issue-btn');
    };

    const _field_term = {
      is_featured: 'การจัดแสดง',
      assigned_department: 'หน่วยงาน',
      assigned_users: 'เจ้าหน้าที่',
      level: 'ความสำคัญ',
      tags: 'แท็ก',
      categories: 'ประเภท',
      neighborhood: 'อาคาร',
      location: 'ตำแหน่งพิน',
      detail: 'ข้อความในรายงาน',
    };

    self.calculateComments = () => {
      function _t(field) {
        return _field_term[field] || field || 'ข้อมูล';
      }
      function parse_acitivity_text(type, action, log, pin) {
        const changed_fields = _.filter(_.map(log.changed_fields, (name, i) => {
          // return null to skip this labelField
          if (name === 'progresses') return null;
          if (name === 'closed_reason') return null;
          const field = {
            name: name,
            previous: log.previous_values[i],
            value: log.updated_values[i]
          };
          if (field.previous === field.value) return null;
          return field;
        }), field => {
          const hidden_fields = ['status'];
          return field !== null && hidden_fields.indexOf(field.name) === -1;
        });

        switch (type) {
          case 'ACTION_TYPE/STATE_TRANSITION':
            const state = action.split('/')[1].toLowerCase();
            if (['resolved', 'resolve'].indexOf(state) >= 0) {
              let msg = 'ปิดเรื่องร้องเรียน'
                //- + '<i class="icon material-icons is-success">check</i>';
              if (pin.closed_reason) {
                msg += ' (' + pin.closed_reason + ')';
              } else {
                msg += ' (สำเร็จ)';
              }
              return msg;
            }
            if (['rejected', 'reject'].indexOf(state) >= 0) {
              let msg = 'ปิดเรื่องร้องเรียน'
                //- + '<i class="icon material-icons is-danger">error_outline</i>';
              if (pin.closed_reason) {
                msg += ' (' + pin.closed_reason + ')';
              }
              return msg;
            }
            if (['assigned', 'assign'].indexOf(state) >= 0) {
              if (changed_fields.length === 0) return ''; // empty string = skip
              return log.user + ' แก้ไข ' + _.map(changed_fields, field => _t(field.name)).join(', ');
            }
            if (['pending', 'unassigned', 'unassign'].indexOf(state) >= 0) {
              return '';
            }
            if (['re_open'].indexOf(state) >= 0) {
              return 'เปิดเรื่องร้องเรียนใหม่อีกครั้ง';
            }
            return '';

          case 'ACTION_TYPE/METADATA':
            if (changed_fields.length === 0) return ''; // empty string = skip
            return log.user + ' แก้ไข ' + _.map(changed_fields, field => _t(field.name)).join(', ');

          default:
            return 'ไม่มีข้อมูล';
        }
      }

      // creation log
      self.comments = [{
        type: 'meta',
        text: 'รายงานเรื่องร้องเรียน',
        photos: [],
        user: _.get(self.pin, 'owner.name', ''),
        timestamp: self.pin.created_time
      }];
      // activity logs
      const normalized_activities = self.activities.map(item => _.merge(_.clone(item), {
        type: 'meta',
        text: parse_acitivity_text(item.actionType, item.action, item, self.pin),
        photos: [],
        //- annotation: item.actionType + ' :: ' + item.action,
        //- user: null,
        //- timestamp: item.updated_time
      }));
      self.comments = self.comments.concat(normalized_activities);
      // pin's comments
      if (self.pin) {
        const normalized_progresses = _.get(self, 'pin.progresses', []).map(item => {
          const c = _.merge(_.clone(item), {
            type: 'comment',
            text: item.detail,
            photos: [],
            user: _.get(item, 'owner.name', ''),
            //- annotation: '',
            timestamp: item.updated_time
          });
          if (!c.text && c.photos.length > 0) {
            c.text = 'อัพโหลดรูป';
          }
          return c;
        });
        self.comments = self.comments.concat(normalized_progresses);
      }
      self.comments = _.filter(self.comments, comment => comment.text || _.get(comment, 'photos.length', 0) > 0)
      self.comments = _.sortBy(self.comments, c => - new Date(c.timestamp));
    }

    self.toggleCloseIssueModal = () => {
      self.open_modal.close_issue = !self.open_modal.close_issue;
      self.update();
    }

    self.selectCloseIssueType = (e) => {
      const select_id = e.currentTarget.dataset.id;
      _.forEach(self.close_issue_form.type, item => {
        item.selected = item.id === select_id;
      });
      self.update();
    }

    // state: pending, assigned, processing, resolved, rejected
    self.commitCloseIssue = (e) => {
      const selected_item = _.find(self.close_issue_form.type, ['selected', true]);
      const next_status = selected_item.value;
      const closed_reason = self.refs.closed_reason_input.value;
      const reason = closed_reason
        ? closed_reason
        : (next_status === 'rejected' ? selected_item.id : '');
      if (!next_status) {
        Materialize.toast('ข้อมูลเพื่อปิดเรื่องร้องเรียนไม่สมบูรณ์ โปรดลองอีกครั้ง', 8000, 'dialog-error large')
        return;
      }
      //- const update = {
      //-   $set: { state: next_status }
      //- }
      //- api.patchPin(self.id, update)
      const update_status = { state: next_status };
      const update_pin = { closed_reason: reason };
      return api.postTransition(self.id, update_status)
      .then(() => api.patchPin(self.id, update_pin))
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      )
      .then(response => self.loadPin())
      .then(() => {
        self.toggleCloseIssueModal();
      });
    };

    self.toggleReopenIssueModal = () => {
      self.open_modal.reopen_issue = !self.open_modal.reopen_issue;
      self.update();
    }
    self.commitReopenIssue = (e) => {
      const next_status = 'pending';
      //- const update = {
      //-   $set: { state: next_status }
      //- }
      //- api.patchPin(self.id, update)
      const update = { state: next_status };
      api.postTransition(self.id, update)
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      )
      .then(response => self.loadPin())
      .then(() => {
        self.toggleReopenIssueModal();
      })
    };

    self.setIssueAsFeatured = (e) => {
      const update_pin = { is_featured: true };
      api.patchPin(self.id, update_pin)
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      )
      .then(response => self.loadPin());
    };

    self.unsetIssueAsFeatured = (e) => {
      const update_pin = { is_featured: false };
      api.patchPin(self.id, update_pin)
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      )
      .then(response => self.loadPin());
    };
