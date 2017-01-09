setting-department
  h1.page-title
    | Department Settings

  .row
    .col.s12.right-align
      a.btn(onclick="{createDepartment}")
        | Create Department

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
          a.btn.btn-small.btn-block(onclick="{ editDepartment(dept._id) }")
            | Edit

  div(class="modal")#edit-department-form
    .modal-header
        h3 Edit Department
    .divider
    .modal-content
        | something

  div(class="modal")#create-department-form
    .modal-header
      h3 Create Department
    .modal-content
      h5 Department name
      .input-field
        input(type="text",name="name")

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

    self.editDepartment = (deptId) => {
        return () => {
            let $modal = $editModal;

            console.log('------');

            $modal.trigger('openModal');
        }
    }

    self.createDepartment = () => {
        let $modal = $createModal;

        let $input = $modal.find('input[name="name"]');
        $input.val('');

        console.log('creating new department');

        $modal.trigger('openModal');
    }

    self.closeCreateModal = () => {
        let $modal = $createModal;
        $modal.trigger('closeModal');
    }

    self.confirmCreate = () => {
        let $modal = $createModal;
        let $input = $modal.find('input[name="name"]');

        console.log('creating ' + $input.val());
        console.log(user)

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
