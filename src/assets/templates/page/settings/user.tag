setting-user
  h1.page-title
    | User List

  .row
    .col.s12.right-align
      a.button.is-accent(onclick="{createUser}")
        | Create User

  .opaque-bg.content-padding.is-overflow-auto
    table.table.is-striped
      thead
          th Name / Email
          th Department
          th Role
          th(style='min-width: 100px;')

      tr(each="{user in users}" ).user
          td
            profile-image.is-round(name='{ user.name }', subtitle='{ user.email }')
          td { _.get(user, 'department.name', '-') }
          td { app.config.role[user.role].name }
          td
            a.button.is-block(onclick="{ editUser(user) }")
              | Edit

  .spacing
  .load-more-wrapper.has-text-centered(show='{ hasMore }')
    a.button.load-more(class='{ "is-loading": !loaded }', onclick='{ loadData }' ) Load More

  #edit-user-form(class="modal")
    .modal-header
      h3 Edit User {editingUser.name}
    .divider
    .modal-content
      .field
        label.label Role
        .control
          .select.is-fullwidth
            select.browser-default(name="role")
              option(each="{ role in app.config.role }", value="{role.id}", selected="{ role.id === editingUser.role }") {role.name}

      .field.department-selector-wrapper
        label.label Department
        .control
          .select.is-fullwidth
            select.browser-default(name="department")
              option(each="{ dept in departments }", value="{dept._id}", selected="{ dept._id === editingUser.department._id }" ) {dept.name}

      .field
        label.label Email
        .control
          input.input(type="text", name="email", value="{editingUser.email}")

      div.padding

    .modal-footer
      .row
        .col.s12
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(onclick="{closeEditUserModal}") Cancel
            .control
              a.button.is-outlined.is-accent(onclick="{confirmEditUser}") Save

  #create-user-form(class="modal")
    .modal-header
      h3 Create User
    .modal-content
      .field
        label.label Name
        .control
          input.input(type="text", name="name")
      .field
        label.label Email
        .control
          input.input(type="text", name="email")
      .field
        label.label Password
        .control
          input.input(type="password", name="password")
      .field
        label.label Confirm Password
        .control
          input.input(type="password", name="confirm-password")

    .modal-footer
      .row
        .col.s12
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(onclick="{closeCreateModal}") Cancel
            .control
              a.button.is-outlined.is-accent(onclick="{confirmCreate}") Create

  script.
    let self = this;
    let $editUserModal, $createModal, $roleSelector, $departmentSelector;

    self.users = [];
    self.hasMore = true;
    self.loaded = true;

    $(document).ready(() => {
      $editUserModal  = $('#edit-user-form').modal();
      $createModal = $('#create-user-form').modal();

      $roleSelector = $editUserModal.find('select[name="role"]')
      $departmentSelector = $editUserModal.find('select[name="department"]');

      $roleSelector.on('change', () => {
        let selectedRole = $roleSelector.val();
      });
    });

    self.on('mount', () => {
      api.getDepartments().then( (res) => {
        self.departments = res.data;
        self.departments = [{
          _id: '',
          name: 'No Department',
          organization: ''
        }].concat(self.departments);
        self.loadData();
      });
    });

    self.loadData = () => {
      const opts = { $skip: self.users.length };
      self.loaded = false;
      api.getUsers( opts ).then( result => {
        self.loaded = true;
        self.users = self.users.concat(result.data)
        self.updateHasMoreButton(result);
        self.update();
      });
    };

    self.updateHasMoreButton = (result) => {
      self.hasMore = ( result.total - ( result.skip + result.data.length ) ) > 0;
    }

    self.editUser = ( userObj ) => {
      return () => {
        self.editingUser = userObj;
        self.update();

        $roleSelector.material_select();
        $departmentSelector.material_select();

        let $modal = $editUserModal;

        $modal.trigger('openModal');
      }
    };

    self.confirmEditUser = () => {
      let patch = {
        role: $roleSelector.val(),
        department: _.compact([$departmentSelector.val()]),
        email: $editUserModal.find('input[name="email"]').val(),
      }

      // Super Admin must has no department
      if( patch.role == "super_admin" ) {
        patch.department = null;
      }

      api.updateUser(self.editingUser._id, patch).then( (res) => {
        if( res.status != "200" ) {
          alert("something wrong : check console");
          console.log(res);
          return;
        }
        self.closeEditUserModal();
        self.loadData();
      });
    };

    self.closeEditUserModal = () => {
      let $modal = $editUserModal;
      $modal.trigger('closeModal');
    };

    self.createUser = () => {
      let $modal = $createModal;

      let $input = $modal.find('input[name="name"]');
      $input.val('');


      $modal.trigger('openModal');
    };

    self.closeCreateModal = () => {
      let $modal = $createModal;
      $modal.trigger('closeModal');
    };

    self.confirmCreate = () => {
      let $modal = $createModal;

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
        if( res.status != "201" ) {
         alert("something wrong : check console");
         console.log(res);
         return;
        }

        self.closeCreateModal();
        self.loadData();
      });
    };
