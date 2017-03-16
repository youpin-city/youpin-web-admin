setting-user
  h1.page-title
    | User List

  .row
    .col.s12.right-align
      a.btn(onclick="{createUser}")
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
            div {user.name}
            .content.is-small
              div {user.email}
          td {user.department.name}
          td {_.find(availableRoles, ['id', user.role]).name}
          td
            a.btn.btn-small.btn-block(onclick="{ editUser(user) }")
              | Edit

  .spacing
  div.load-more-wrapper
    a.load-more(class="{active: hasMore}", onclick="{ loadData }" ) Load More

  div#edit-user-form(class="modal")
    .modal-header
      h3 Edit User {editingUser.name}
    .divider
    .modal-content
      h5 Role
      .input-field.col.s12
        select(name="role")
          option(each="{ role in availableRoles }", value="{role.id}", selected="{ role.id === editingUser.role }") {role.name}
      div.department-selector-wrapper
        h5 Department
        .input-field.col.s12
          select(name="department")
            option(each="{ dept in departments }", value="{dept._id}", selected="{ dept._id === editingUser.department._id }" ) {dept.name}
      h5 Email
      .input-field
        input(type="text", name="email", value="{editingUser.email}")
      div.padding

    .modal-footer
      .row
        .col.s12.right-align
          a(onclick="{closeEditUserModal}").btn-flat Cancel
          | &nbsp;
          a(onclick="{confirmEditUser}").btn Save

  div(class="modal")#create-user-form
    .modal-header
      h3 Create User
    .modal-content
      h5 Name
      .input-field
        input(type="text",name="name")
      h5 Email
      .input-field
        input(type="text",name="email")
      h5 Password
      .input-field
        input(type="password",name="password")
      h5 Confirm Password
      .input-field
        input(type="password",name="confirm-password")

    .modal-footer
      .row
        .col.s12.right-align
          a(onclick="{closeCreateModal}").btn-flat Cancel
          | &nbsp;
          a(onclick="{confirmCreate}").btn Create

  script.
    let self = this;
    let $editUserModal, $createModal, $roleSelector, $departmentSelector;

    self.users = [];
    self.hasMore = true;
    self.availableRoles = opts.availableRoles || [];

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
      api.getUsers( opts ).then( result => {
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
