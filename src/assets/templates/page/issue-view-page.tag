issue-view-page
  .container
    nav.level.is-mobile
      .level-left.content-padding
        .level-item
          .issue-title.title \#{ id.slice(-4) }
        .level-item(show='{ isClosed() }')
          .tag.is-large.is-danger ปิดเรื่อง
        .level-item(show='{ isClosed() }')
          span(show='{ pin.status === "rejected" }')
            i.icon.material-icons.is-danger error_outline
          span(show='{ pin.status === "resolved" }')
            i.icon.material-icons.is-success check
          span { _.startCase(pin.closed_reason) }
      .level-right.content-padding
        .level-item
          .control
            input(type='text', id='select_priority', ref='select_priority', placeholder='เลือกระดับความสำคัญ')
        .level-item
          a#issue-more-menu-btn(href='#')
            i.icon.material-icons settings
          dropdown-menu(target='#issue-more-menu-btn', position='bottom right', menu='{ create_issue_menu_list }')

    .section(if='{ !loaded }')
      //- loading-bar
      .title Loading..
    .section(if='{ loaded }')
      .columns(each='{ pin in [pin] }')
        .column.is-3
          .issue-photos
            div(if='{ !(pin.photos && pin.photos.length) }')
              div No photo
            div(if='{ pin.photos && pin.photos.length }')
              //- figure.image.is-square
              //-   img(src='{ util.site_url(pin.photos[0]) }')
              image-slider-lightbox(data='{ pin.photos }', highlight='{ true }')

        .column.is-5(hide='{ isEditing("info") }')
          .issue-view-info
            .issue-detail { pin.detail }
            hr
            .issue-report-detail
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr(show='{ pin.owner }')
                    th รายงานโดย
                    td
                      .field.is-inline { pin.owner.name }
                      a#issue-owner-contact-btn.field.is-inline.button.is-tiny(href='#', data-id='{ pin.owner._id }')
                        span ติดต่อกลับ
                      dropdown-menu(ref='owner_contact_menu', target='#issue-owner-contact-btn', position='bottom left')

                  tr(if='{ pin.created_time }')
                    th รายงานเมื่อ
                    td
                      .field.is-inline { moment(pin.created_time).format(app.config.format.datetime_full) }
            hr
            .issue-more-detail
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr
                    th สถานที่
                    td
                      .field.is-inline(show='{ pin.neighborhood && pin.neighborhood.length }') { pin.neighborhood.join(', ') }
                      a#map-view-btn.field.is-inline.button.is-tiny(show='{ !!pin.location }', href='#', data-lat='{ pin.location.coordinates[0] }', data-long='{ pin.location.coordinates[1] }')
                        | ดูบนแผนที่
                      issue-map-modal(data-id='{ id }', name='{ _.get(pin, "neighborhood.0") }', location='{ _.get(pin, "location.coordinates", []).join(",") }', target='#map-view-btn')
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

        #edit-issue-panel.column.is-4(hide='{ isEditing("info") }')
          // assigned department
          .section
            .field
              label.label หน่วยงานรับผิดชอบ
                .is-pulled-right
                  a(hide='{ isEditing("department") }', href='#', onclick='{ toggleEdit("department") }')
                    small แก้ไข
                  a(show='{ isEditing("department") }', href='#', onclick='{ toggleEdit("department") }')
                    small ปิด
              .control(hide='{ isEditing("department") }')
                div(show='{ !!pin.assigned_department }')
                  profile-image.is-round-box(each='{ dept, i in [pin.assigned_department] }', name='{ _.get(dept, "name") }')
                div(hide='{ !!pin.assigned_department }')
                  div ยังไม่มีหน่วยงาน
              .control(show='{ isEditing("department") }')
                input(type='text', id='select_department', ref='select_department', placeholder='เลือกหน่วยงาน')

          //- assigned staff
          .section
            .field
              label.label เจ้าหน้าที่รับผิดชอบ
                .is-pulled-right
                  a(hide='{ isEditing("staff") }', href='#', onclick='{ toggleEdit("staff") }')
                    small แก้ไข
                  a(show='{ isEditing("staff") }', href='#', onclick='{ toggleEdit("staff") }')
                    small ปิด
              .control(hide='{ isEditing("staff") }')
                div(show='{ !!pin.assigned_users.length }')
                  ul.selected-list
                    li(each='{ staff, i in pin.assigned_users }')
                      profile-image.is-round-box(name='{ _.get(staff, "name") }', subtitle='{ _.get(staff, "department.name") }')
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
          .section
            hr
            .action
              button.button.is-outlined.is-accent.is-block(show='{ !isClosed() }', onclick='{ toggleCloseIssueModal }')
                span.text ปิดเรื่อง
              button.button.is-outlined.is-block(show='{ isClosed() }', onclick='{ toggleReopenIssueModal }')
                span.text เปิดเรื่อง

        .issue-edit-info.column.is-9(show='{ isEditing("info") }')
          .issue-detail
            .field
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
                          input.input(ref='neighborhood_input', type='text', value='{ _.get(pin, "neighborhood.0", "") }', placeholder='ตึก ห้อง')
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
              a.button.is-outlined(class='{ "is-disabled": saving_info }', onclick='{ toggleEdit("info") }') Cancel
            .control
              a.button.is-outlined.is-accent(class='{ "is-loading": saving_info }', onclick='{ updateIssueInfo }') Save

    #progress-section.section(if='{ loaded }')
      .title ความคืบหน้า
      .progress-list
        // offer new post comment editor
        article.media.progress-item.progress-editor.is-block-mobile
          .media-left
            profile-image.is-round(name='{ user.name }', subtitle='{ user.dept && user.dept.name }')
          .media-content
            form(ref='comment_form')
              .field
                .control
                  textarea.textarea(ref='comment_input')
              .field
                .control
                  .level
                    .level-left
                      label.button.is-accent(for='comment-photo-input')
                        i.icon.material-icons add_a_photo
                      input(show='{ false }', id='comment-photo-input', ref='comment_photo_input', type='file', accept="image/*")
                    .level-right
                      button.button.is-accent(onclick='{ submitComment }') ส่งความคืบหน้า
        // previous posts
        article.media.progress-item.is-block-mobile(show='{ comments && comments.length > 0 }', each='{ comment, i in comments }')
          .media-left
            profile-image.is-round(show='{ comment.type === "comment" }', name='{ comment.user }')
            profile-image.is-round.is-small(show='{ comment.type === "meta" }', name='{ comment.user }')
          .media-content
            .content.pre { comment.text }
            div(show='{ comment.annotation }')
              small { comment.annotation }
            .datetime
              small { moment(comment.timestamp).format(app.config.format.datetime_full) }

          .media-right(show='{ comment.photos.length }')
            image-slider-lightbox(data='{ comment.photos }', column='6', highlight='{ false }')
            //- .columns
            //-   .column.is-6(each='{ photo, i in comment.photos }')
            //-     figure.image.is-full-width
            //-       img(src='{ util.site_url(photo) }')
            //- span.datetime { moment(comment.timestamp).format(app.config.format.datetime_full) }

  // Close Issue Modal
  #close-issue-modal.modal.bulma-modal(ref='close_issue_modal', class='{ "is-active": open_modal.close_issue }')
    .modal-background(onclick='{ toggleCloseIssueModal }')
    .modal-card
      header.modal-card-header
        //- .is-pulled-right
        //-   button.delete.close-btn(onclick='{ toggleCloseIssueModal }')
        .title ปิดเรื่อง

      section.modal-card-body
        table.table.is-borderless.is-narrow.is-static
          tbody
            tr
              td
                p ปิดเรื่องร้องเรียน โดยที่
              td
                ul.menu-list
                  li(each='{ item in close_issue_form.type }')
                    a(href='#', data-id='{ item.id }', class='{ "is-active": item.selected }', onclick='{ selectCloseIssueType }')
                      i.icon.material-icons { item.icon }
                      span { item.name }
                    //- แก้ไขเรื่องร้องเรียนเสร็จแล้ว
                  //- li
                  //-   a(href='#') ไม่สามารถแก้ไขเรื่องร้องเรียนนี้
                  //- li
                  //-   a(href='#') เป็นสแปมหรือแจ้งเหตุไม่เหมาะสม

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
        //- .is-pulled-right
        //-   button.delete.close-btn(onclick='{ toggleReopenIssueModal }')
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
    self.loaded = false;
    self.pin = null;
    self.activities = [];
    self.comments = [];
    self.editing_info = false;
    self.saving_info = false;
    self.editing_department = false;
    self.editing_staff = false;
    self.open_modal = {
      close_issue: false,
      reopen_issue: false
    };

    self.create_issue_menu_list = () => [
      {
        id: 'edit-issue-btn',
        name: 'แก้ไขข้อมูล',
        url: '#',
        target: '',
        onclick: (e) => { self.toggleEdit('info')(); }
      },
      {
        id: 'merge-issue-btn',
        name: 'แจ้งรายงานซ้ำ',
        url: util.site_url('merge/') + self.id,
        target: '',
        onclick: (e) => { console.log('Merge'); }
      }
    ];

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

    self.loadPin = () => {
      return api.getPin(self.id)
      .then(data => {
        self.loaded = true;
        self.pin = data;
        self.update();

        self.initSelectDepartment();
        self.initSelectStaff();
        self.initSelectCategory();
        self.initSelectTag();
        self.initSelectPriority();
        self.loadPinActivities();

        // contact menu
        if (self.refs.owner_contact_menu && self.pin.owner) {
          self.refs.owner_contact_menu.setMenu(() => [
            {
              id: 'contact-owner-email-btn',
              name: 'Email: ' + self.pin.owner.email,
              url: '#mailto:' + self.pin.owner.email,
              target: '',
              onclick: (e) => { alert('email: ' +  self.pin.owner.email); }
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
            return '<profile-image class="is-round-box is-small" name="' + escape(name) + '"></profile-image>';
          }
        },
        load: function(query, callback) {
          //- if (!query.length) return callback();
          api.getDepartments({ })
          .then(result => {
            callback(result.data);
          });
        },
        onChange: function(value) {
          const update = value ? { assigned_department: value }
            : { assigned_department: null };
          api.patchPin(self.id, update)
          .catch(err =>
            Materialize.toast(err.message, 8000, 'dialog-error large')
          )
          .then(response => self.loadPin());
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
            return '<profile-image class="is-round is-small" name="' + escape(name) + '" subtitle="' + escape(department) + '"></profile-image>';
          }
        },
        load: function(query, callback) {
          //- if (!query.length) return callback();
          let opts;
          if (util.check_permission('view_all_staff', user && user.role)) {
            opts = {};
          } else if (util.check_permission('view_department_staff', user && user.role)) {
            opts = { department: user.department._id };
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

    self.choosePhoto = (e) => {
      if (e && e.preventDefault) e.preventDefault();
    };

    self.submitComment = (e) => {
      if (e && e.preventDefault) e.preventDefault();
      const files = self.refs.comment_photo_input.files;
      const progress_data = {
        photos: files.length > 0
          ? [window.URL.createObjectURL(files[0])]
          : [],
        detail: self.refs.comment_input.value
      };
      console.log('process update:', progress_data);
      if (!progress_data.detail && progress_data.photos.length === 0) {
        Materialize.toast('พิมพ์ข้อความหรือเลือกรูป อธิบายความคืบหน้า', 8000, 'large')
        return;
      }

      // upload photo first, if any

      return Promise.resolve({})
      // upload photo if need
      .then(() => {
        if (progress_data.photos.length === 0) return null;

        const form = new FormData();
        return fetch(progress_data.photos[0])
        .then(response => response.blob())
        .then(blob => {
          console.log('1', progress_data);
          form.append('image', blob);
          return api.postPhoto(form);
        })
        .then(response => response.json())
        .then(photo_data => {
          progress_data.photos[0] = photo_data.url;
          //- console.log('2', progress_data, photo_data);
          //- return api.patchPin(id, {
          //-   //- owner: user._id,
          //-   $push: { progresses: progress_data }
          //- });
        })
        //- .then(response => {
        //-   console.log('3', response);
        //-   //- $progress.find('textarea').val('');
        //-   //- $progress.find('input[type="file"]').val('');
        //- })
        .catch(err =>
          Materialize.toast(err.message, 8000, 'dialog-error large')
        );
      })
      // create progress request (text + photo)
      .then(() => {
        return api.patchPin(self.id, {
          $push: { progresses: progress_data }
        })
        .then(response => {
          self.refs.comment_form.reset();
        })
        .catch(err =>
          Materialize.toast(err.message, 8000, 'dialog-error large')
        )
        .then(() => self.loadPin());
      });
    }

    self.updateIssueInfo = (e) => {
      const update = {
        //- $set: {
          detail: self.refs.description_input.value,
          neighborhood: _.compact([self.refs.neighborhood_input.value]),
          //- 'location.coordinates': [
          //-   self.refs.location_lat_input.value,
          //-   self.refs.location_long_input.value
          //- ],
          categories: _.compact(self.refs.select_categories.value.split(',')).map(cat => _.trim(cat)),
          tags: _.compact(self.refs.select_tags.value.split(',')).map(tag => _.trim(tag))
        //- }
      }
      console.log('update:', update);
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
      function parse_acitivity_text(type, action, log) {
        switch (type) {
          case 'ACTION_TYPE/STATE_TRANSITION':
            const state = action.split('/')[1].toLowerCase();
            if (['resolved', 'rejected'].indexOf(state) >= 0) {
              return 'ปิดเรื่องร้องเรียน';
            }
            return 'เปิดเรื่องร้องเรียนใหม่อีกครั้ง';

          case 'ACTION_TYPE/METADATA':
            const prog_index = log.changed_fields.indexOf('progresses');
            if (prog_index >= 0) {
              log.changed_fields.splice(prog_index, 1);
              log.previous_values.splice(prog_index, 1);
              log.updated_values.splice(prog_index, 1);
            }
            if (log.changed_fields.length === 0) {
              return '';
            }
            //- if (log.changed_fields.length === 1 && log.changed_fields[0] === 'progresses)
            return 'แก้ไข ' + _.map(log.changed_fields, field => _t(field)).join(', ');
          default:
            return 'ไม่มีข้อมูล';
        }
      }
      const normalized_activities = self.activities.map(item => _.merge(_.clone(item), {
        type: 'meta',
        text: parse_acitivity_text(item.actionType, item.action, item),
        photos: [],
        //- annotation: item.actionType + ' :: ' + item.action,
        //- user: null,
        //- timestamp: item.updated_time
      }));
      self.comments = [].concat(normalized_activities);
      if (self.pin) {
        const normalized_comments = _.get(self, 'pin.progresses', []).map(item =>
          _.merge(_.clone(item), {
            type: 'comment',
            text: item.detail,
            photos: [],
            user: null,
            //- annotation: '',
            timestamp: item.updated_time
          })
        );
        self.comments = self.comments.concat(normalized_comments);
      }
      self.comments = _.filter(self.comments, comment => comment.text)
      self.comments = _.sortBy(self.comments, c => - new Date(c.timestamp));
      //- console.log(self.comments, 'comments');
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
      const reason = next_status === 'rejected' ? selected_item.id : '';
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
      })
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
