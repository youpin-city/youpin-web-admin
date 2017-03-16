setting-department
  h1.page-title
    | Department Settings

  .row
    .col.s12.right-align
      a.btn(onclick="{createDepartment}")
        | Create Department

  .opaque-bg.content-padding
    table
      thead
        tr
          th Department
          th(style='width: 120px;')
      tbody
        tr(each="{dept in departments}" ).department
          td
            b {dept.name}
          td
            a.btn.btn-small.btn-block(onclick="{ editDepartment(dept._id, dept.name) }")
              | Edit

  #edit-department-form.modal
    .modal-header
        h3 Edit Department
    .divider
    .modal-content
      h5 Department name
      .input-field.control
        input.input(type="text", name="departmentName", value="{editingDepartment.name}")

    .modal-footer
      .row
        .col.s12.right-align
          a(onclick="{closeEditDepartmentModal}").btn-flat Cancel
          | &nbsp;
          a(onclick="{confirmEditDepartment}").btn Save

  div(class="modal")#create-department-form
    .modal-header
      h3 Create Department
    .modal-content
      h5 Department name
      .input-field.control
        input.input(type="text",name="name")

    .modal-footer
      .row
        .col.s12.right-align
          a(onclick="{closeCreateModal}").btn-flat Cancel
          | &nbsp;
          a(onclick="{confirmCreate}").btn Create

  script.
    let self = this;
    let $editModal, $createModal;

    $(document).ready( () => {
        $editModal  = $('#edit-department-form').modal();
        $createModal = $('#create-department-form').modal();
    })

    this.departments  = []

    self.loadData = () => {
      api.getDepartments().then( (res) => {
        self.departments = res.data;
        self.update();
      });
    }

    self.loadData();

    self.editDepartment = (deptId, deptName) => {
        return () => {
            let $modal = $editModal;
            self.editingDepartment = {
              id: deptId,
              name: deptName,
            }

            $modal.trigger('openModal');
        }
    }

    self.createDepartment = () => {
        let $modal = $createModal;

        let $input = $modal.find('input[name="name"]');
        $input.val('');

        $modal.trigger('openModal');
    }

    self.closeCreateModal = () => {
        let $modal = $createModal;
        $modal.trigger('closeModal');
    }

    self.confirmCreate = () => {
        let $modal = $createModal;
        let $input = $modal.find('input[name="name"]');

        api.createDepartment( $input.val() )
         .then( (res) => {
            if( res.status != "201" ) {
             alert("something wrong : check console");
             console.log(res);
             return;
            }

            self.closeCreateModal();
            self.loadData();
         });
    }

    self.closeEditDepartmentModal = () => {
      let $modal = $editModal;
      $modal.trigger('closeModal');
    };

    self.confirmEditDepartment = () => {
      const patch = {
        name: $editModal.find('input[name="departmentName"]').val(),
      }

      api.updateDepartment(self.editingDepartment.id, patch)
        .then((res) => {
          if (res.status !== "200") {
            alert("Cannot update department. Please contact system administrator.");
            console.log(res);
            return;
          }
          self.closeEditDepartmentModal();
          self.loadData();
        });
    };
