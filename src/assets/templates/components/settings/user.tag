setting-user
  h1.page-title
    | User Settings

  .row
    .col.s12.right-align
      a.btn(onclick="{createUser}")
        | Create User

  .opaque-bg.content-padding
    table
      thead
          th Name
          th Email
          th Department
          th Role
          th(style='min-width: 100px;')

      tr(each="{user in users}" ).user
          td {user.name}
          td {user.email}
          td {user.department.name}
          td {user.role}
          td
            a.btn.btn-small.btn-block(onclick="{ changeRole(user) }")
              | Edit

  div#change-role-form(class="modal")
    .modal-header
      h3 Change role of {editingUser.name}
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
      div.padding

    .row
      .col.s12.right-align
        a(onclick="{closeChangeRoleModal}").btn-flat Cancel
        | &nbsp;
        a(onclick="{confirmChangeRole}").btn Save

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

    .row
      .col.s12.right-align
        a(onclick="{closeCreateModal}").btn-flat Cancel
        | &nbsp;
        a(onclick="{confirmCreate}").btn Create

  script.
    let self = this;
    let $changeRoleModal, $createModal, $roleSelector, $departmentSelector;

    self.availableRoles = opts.availableRoles || [];
    $(document).ready(() => {
      $changeRoleModal  = $('#change-role-form').modal();
      $createModal = $('#create-user-form').modal();

      $roleSelector = $changeRoleModal.find('select[name="role"]')
      $departmentSelector = $changeRoleModal.find('select[name="department"]');

      $roleSelector.on('change', () => {
        let selectedRole = $roleSelector.val();
      });
    });

    self.users = [];


    self.loadData = () => {
      api.getUsers().then( (res) => {
        self.users = res.data;
        self.update();
      });
    };

    api.getDepartments().then( (res) => {
      self.departments = res.data;
      self.departments = [{
        _id: '',
        name: 'No Department',
        organization: ''
      }].concat(self.departments);
      self.loadData();
    });

    self.changeRole = ( userObj ) => {
      return () => {
        self.editingUser = userObj;
        self.update();

        $roleSelector.material_select();
        $departmentSelector.material_select();

        let $modal = $changeRoleModal;

        $modal.trigger('openModal');
      }
    };

    self.confirmChangeRole = () => {
      let patch = {
        role: $roleSelector.val(),
        department: _.compact([$departmentSelector.val()])
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
        self.closeChangeRoleModal();
        self.loadData();
      });
    };

    self.closeChangeRoleModal = () => {
      let $modal = $changeRoleModal;
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
