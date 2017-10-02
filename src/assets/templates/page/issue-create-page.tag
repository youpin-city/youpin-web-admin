issue-create-page
  .container
    nav.level.is-mobile.is-wrap
      .level-left.content-padding
        .level-item
          .issue-title.title
            i.icon.material-icons announcement
            | สร้างเรื่องร้องเรียน

    .section
      .columns
        //- .column.is-3
        //-   .issue-photos
        //-     div
        //-       div No photo

        .issue-edit-info.column.is-12
          .issue-detail
            .field
              label ชื่อผู้ร้อง
              .control
                input.input(type='text', ref='reporter_name_input', placeholder='')

          br

          .issue-detail
            .field
              label ชื่อ LINE ผู้ร้อง
              .control
                input.input(type='text', ref='reporter_line_name_input', placeholder='')

          br

          .issue-detail
            .field
              label รายละเอียด
              .control
                textarea.textarea(ref='description_input', placeholder='รายละเอียดปัญหา หรือข้อเสนอแนะที่ถูกรายงานเข้ามา')

          hr

          .issue-photos
            .field(show='{ update_data.images.length > 0 }')
              .columns.is-wrap
                .column.is-12.is-mobile(each='{ img, i in update_data.images }')
                  figure.image(style='background-image: url("{ img }")')
                    .img-tool
                      button.delete(onclick='{ removeFormPhoto("update_data")(i) }')
                    //- img(src='{ img }')
            .field
              .control
                form.is-fullwidth(ref='issue_photo_form')
                  label.button.is-accent.is-block(for='issue-photo-input', class='{ "is-loading": saving_info_photo, "is-disabled": saving_info }')
                    i.icon.material-icons add_a_photo
                  input(show='{ false }', id='issue-photo-input', ref='issue_photo_input', type='file', accept='image/*', multiple, onchange='{ chooseFormPhoto("update_data", "issue_photo_form", "saving_info_photo") }')

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
                          input.input(ref='location_lat_input', type='text', value='{ _.get(pin, "location.coordinates.0", "") }', placeholder='Latitude เช่น 13.xxxxxx')
                      .field
                        .control
                          input.input(ref='location_long_input', type='text', value='{ _.get(pin, "location.coordinates.1", "") }', placeholder='longitude เช่น 100.xxxxxx')
            .column.is-6
              table.table.is-borderless.is-narrow.is-static
                tbody
                  tr
                    th ประเภทเรื่องร้องเรียน
                    td
                      .field
                        .control
                          input(type='text', id='select_categories', ref='select_categories', placeholder='เลือกประเภท')

                  tr
                    th หน่วยงานรับผิดชอบ
                    td
                      .field
                        .control
                          input(type='text', id='select_department', ref='select_department', placeholder='เลือกหน่วยงาน')
                  
                  //- tr
                  //-   th แท็ก
                  //-   td
                  //-     .field
                  //-       .control
                  //-         input(type='text', id='select_tags', ref='select_tags', placeholder='เลือกแท็ก')
          hr
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(class='{ "is-disabled": saving_info }', href='{ util.site_url(\'/issue\') }') ยกเลิก
            .control
              a.button.is-outlined.is-accent(class='{ "is-loading": saving_info }', onclick='{ updateIssueInfo }') สร้าง

  script.
    const self = this;
    self.saving_info = false;
    self.update_data = { photos: [], images: [] };
    self.assigned_department;

    self.on('mount', () => {
      self.initSelectDepartment();
      self.initSelectCategory();
      self.initSelectTag();
      //- self.initSelectPriority();
    });

    self.initSelectDepartment = () => {
      $(self.refs.select_department).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        searchField: 'name',
        options: [], // all choices
        //- items: assigned_dept ? [assigned_dept._id] : [], // selected choices
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
          self.assigned_department = value

          //- const update = value ? { assigned_department: value }
          //-   : { assigned_department: null };
          // force state change to assigned
          // when assign department for the first time
          // (when it's still 'pending')
          //- const should_change_state = !!value && self.pin.status === 'pending';
          //- if (should_change_state) {
          //-   update.state = 'assigned';
          //- }

          //- (should_change_state
          //- ? api.postTransition(self.id, update)
          //- : api.patchPin(self.id, update))
          //- .catch(err =>
          //-   Materialize.toast(err.message, 8000, 'dialog-error large')
          //- )
          //- .then(() => self.loadPin());
        }
      });
    }

    self.initSelectCategory = () => {
      const select = self.refs.select_categories;
      const cat_list = app.get('issue.categories') || [];
      //- const selected_cat_list = self.pin.categories || [];
      $(select).selectize({
        maxItems: 1,
        valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        options: cat_list, // all choices
        //- items: selected_cat_list, // selected choices
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
      });
    }

    self.initSelectTag = () => {
      const select = self.refs.select_tags;
      //- const select = $(self.root).find('#select_tags').get(0); //self.refs.select_tags;
      //- const tag_list = self.pin.tags.map(tag => ({ id: tag, name: tag }));
      $(select).selectize({
        valueField: 'id',
        labelField: 'name',
        //- options: tag_list, // all choices
        //- items: _.map(tag_list, 'id'), // selected choices
        create: true,
        render: {
          option_create: function(data, escape) {
            return '<div class="create">เพิ่ม <strong>' + escape(data.input) + '</strong></div>';
          }
        }
      });
    }

    self.updateIssueInfo = (e) => {
      const pin_location = self.refs.location_lat_input.value && self.refs.location_long_input.value
      ? {
        type: 'Point',
        coordinates: [
          self.refs.location_lat_input.value,
          self.refs.location_long_input.value
        ]
      } : null;
      // auto assign own's department if permission allowed
      const assigned_department = util.check_permission('create_issue_auto_assign_department', user && user.role)
        ? _.get(user, 'dept._id') : null;
      // auto assign self if permission allowed
      const assigned_users = util.check_permission('create_issue_auto_assign_self', user && user.role)
        ? [_.get(user, '_id')] : [];
      // new issue data
      const update = {
        provider: user._id,
        owner: user._id,
        organization: _.get(app, 'config.organization.id'),
        assigned_users: assigned_users,
        reporter: {
          name: self.refs.reporter_name_input.value,
          line: self.refs.reporter_line_name_input.value
        },
        detail: self.refs.description_input.value,
        photos: self.update_data.photos,
        assigned_department: self.assigned_department || null,
        level: '2', // normal
        categories: _.compact(self.refs.select_categories.value.split(',')).map(cat => _.trim(cat)),
        //- tags: _.compact(self.refs.select_tags.value.split(',')).map(tag => _.trim(tag)),
        neighborhood: _.compact([self.refs.neighborhood_input.value]),
        location: pin_location
      };

      let new_issue_id;
      self.saving_info = true;
      api.createPin(update)
      .then(response => {
        new_issue_id = response._id;
        if (!response.assigned_department) return true;
        // force state change to assigned
        // when assign department for the first time
        return api.postTransition(new_issue_id, {
          state: 'assigned',
          assigned_department: response.assigned_department
        });
      })
      .then(() => {
        location.href = util.site_url('/issue/' + new_issue_id);
      })
      .catch(err => {
        Materialize.toast(err.message, 8000, 'dialog-error large')
      })
      .then(() => {
        self.saving_info = false;
        self.update();
      });
    };

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
        console.log('file',file)
        const photo_blob_url = window.URL.createObjectURL(file);
        console.log('photo_blob_url', photo_blob_url)
        return fetch(photo_blob_url)
        .then(response => response.blob())
        .then(blob => {
          const form = new FormData();
          form.append('image', blob);
          return api.postPhoto(form);
        })
        .then(response => response.json())
        .then(photo_data => {
          console.log('photo_data', photo_data)
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