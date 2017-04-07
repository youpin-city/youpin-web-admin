setting-user
  nav.level.is-mobile.is-wrap
    .level-left
      .level-item
        .title เจ้าหน้าที่
      .level-item
        .control(style='width: 140px;')
          input(type='text', id='select_department', ref='select_department', placeholder='แสดงตามหน่วยงาน')

    .level-right
      .level-item
        .control
          a.button.is-accent(onclick="{createUser}")
            | สร้างบัญชีเจ้าหน้าที่

  .is-overflow-auto
    table.table.is-striped
      thead
        tr
          th ชื่อ
      tr(each="{user in users}" ).user
          td
            .user-media.media
              .media-left
                profile-image.is-round(name='{ user.name }', subtitle='{ user.email }')
              .media-content
                div { _.get(user, 'department.name', '-') }
                div { app.config.role[user.role].name }
              .media-right
                a.is-plain(id='row-menu-btn-{ user._id }', href='#')
                  i.icon.material-icons more_horiz
                dropdown-menu(target='#row-menu-btn-{ user._id }', position='bottom right', menu='{ row_menu_list(user) }')

  .spacing
  .load-more-wrapper.has-text-centered(show='{ hasMore }')
    a.button.load-more(class='{ "is-loading": !loaded }', onclick='{ loadMore }' ) Load More

  #edit-user-form(class="modal")
    .modal-header
      h3 แก้ไขข้อมูลเจ้าหน้าที่
    .divider
    .modal-content
      .field
        label.label ชื่อ
        .control
          input.input(type="text", name="name", value="{ editingUser && editingUser.name }")
      .field
        label.label ตำแหน่ง
        .control
          .select.is-fullwidth
            select.browser-default(name="role")
              option(each="{ role in app.config.role }", value="{role.id}", selected="{ editingUser && role.id === editingUser.role }") {role.name}

      .field.department-selector-wrapper
        label.label หน่วยงาน
        .control
          .select.is-fullwidth
            select.browser-default(name="department")
              option(each="{ dept in departments }", value="{dept._id}", selected="{ editingUser && dept._id === editingUser.department._id }" ) {dept.name}

      .field
        label.label อีเมล
        .control
          input.input(type="text", name="email", placeholder="name@email.com", value="{ editingUser && editingUser.email }")

      div.padding

    .modal-footer
      .row
        .col.s12
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(onclick="{closeEditUserModal}") ยกเลิก
            .control
              a.button.is-outlined.is-accent(onclick="{confirmEditUser}") บันทึก

  #create-user-form(class="modal")
    .modal-header
      h3 สร้างบัญชีเจ้าหน้าที่
    .modal-content
      .field
        label.label ชื่อ
        .control
          input.input(type="text", name="name")
      .field
        label.label อีเมล
        .control
          input.input(type="text", name="email", placeholder="name@email.com")
      .field
        label.label รหัสผ่าน
        .control
          input.input(type="password", name="password")
      .field
        label.label ยืนยันรหัสผ่าน
        .control
          input.input(type="password", name="confirm-password")

    .modal-footer
      .row
        .col.s12
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(onclick="{closeCreateModal}") ยกเลิก
            .control
              a.button.is-outlined.is-accent(onclick="{confirmCreate}") สร้างบัญชีเจ้าหน้าที่

  script.
    const self = this;

    self.users = [];
    self.hasMore = true;
    self.loaded = true;
    self.current_filter = {};
    self.query = {};

    self.row_menu_list = (user) => () => [
      {
        id: 'edit-user-btn-' + user._id,
        name: 'แก้ไข',
        url: '#',
        target: '',
        onclick: (e) => { self.editUser(user)(); }
      }
    ];

    self.on('before-mount', () => {
      if (self.opts.department) {
        const depts = self.opts.department.split(':');
        self.query.department = { _id: depts[0], name: depts[1] };
        self.current_filter.department = depts[0]; // self.opts.department;
      }
    });

    self.on('mount', () => {
      self.$editUserModal  = $('#edit-user-form').modal();
      self.$createModal = $('#create-user-form').modal();

      self.$roleSelector = self.$editUserModal.find('select[name="role"]')
      self.$departmentSelector = self.$editUserModal.find('select[name="department"]');

      self.initSelectDepartment();
      api.getDepartments().then( (res) => {
        self.departments = res.data;
        self.loadData();
      });
    });

    self.loadData = (reset = true) => {
      if (reset) self.users = [];
      const opts = _.merge(self.current_filter, { $skip: self.users.length });
      self.loaded = false;
      api.getUsers( opts ).then( result => {
        self.loaded = true;
        self.users = self.users.concat(result.data)
        self.updateHasMoreButton(result);
        self.update();
      });
    };

    self.loadMore = (e) => {
      return self.loadData(false);
    }

    self.updateHasMoreButton = (result) => {
      self.hasMore = ( result.total - ( result.skip + result.data.length ) ) > 0;
    }

    self.editUser = ( userObj ) => {
      return () => {
        self.editingUser = userObj;
        self.update();

        self.$roleSelector.material_select();
        self.$departmentSelector.material_select();

        let $modal = self.$editUserModal;

        $modal.trigger('openModal');
      }
    };

    self.confirmEditUser = () => {
      let patch = {
        name: self.$editUserModal.find('input[name="name"]').val(),
        role: self.$roleSelector.val(),
        department: _.compact([self.$departmentSelector.val()]),
        email: self.$editUserModal.find('input[name="email"]').val(),
      }

      // Super Admin must has no department
      if( patch.role == "super_admin" ) {
        patch.department = null;
      }

      api.updateUser(self.editingUser._id, patch).then( (res) => {
        self.closeEditUserModal();
        self.loadData();
      })
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      );
    };

    self.closeEditUserModal = () => {
      let $modal = self.$editUserModal;
      $modal.trigger('closeModal');
    };

    self.createUser = () => {
      let $modal = self.$createModal;

      let $input = $modal.find('input[name="name"]');
      $input.val('');


      $modal.trigger('openModal');
    };

    self.closeCreateModal = () => {
      let $modal = self.$createModal;
      $modal.trigger('closeModal');
    };

    self.confirmCreate = () => {
      let $modal = self.$createModal;

      let fields = ['name', 'email', 'password', 'confirm-password'];
      let userObj = _.reduce( fields, (acc, f) => {
        acc[f] = $modal.find('input[name="'+f+'"]').val();
        return acc;
      }, {} );

      if( userObj['confirm-password'] != userObj['password'] ) {
        alert('Password is not matched!');
        return;
      }

      delete userObj['confirm-password'];

      api.createUser(userObj)
      .then( (res) => {
        self.closeCreateModal();
        self.loadData();
        location.reload();
      })
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      );
    };

    self.initSelectDepartment = () => {
      const departments = _.compact([
        { _id: 'all', name: 'หน่วยงานทั้งหมด' }
      ].concat(self.query.department));
      $(self.refs.select_department).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        //- searchField: 'name',
        options: _.compact(departments), // all choices
        items: [self.current_filter.department || 'all'], // selected choices
        create: false,
        allowEmptyOption: false,
        //- hideSelected: true,
        preload: true,
        load: function(query, callback) {
          //- if (!query.length) return callback();
          api.getDepartments({ })
          .then(result => {
            callback(result.data);
          });
        },
        onChange: function(value) {
          delete self.current_filter.department;
          if (value && value !== 'all') {
            self.current_filter.department = value;
          }
          console.log(self.current_filter, 'filter dept');
          self.loadData();
        }
      });
    }
