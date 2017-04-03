setting-department
  h1.page-title
    | หน่วยงาน

  .row
    .col.s12.right-align
      a.button.is-accent(onclick="{createDepartment}")
        | สร้างหน่วยงาน

  .opaque-bg.content-padding.is-overflow-auto
    table.table.is-striped
      thead
        tr
          th หน่วยงาน
          th(style='width: 200px;')
      tbody
        tr(each="{dept in departments}" ).department
          td
            profile-image.is-round-box(name='{ dept.name }')
          td
            .field.is-inline
              a.button.is-block(href='{ util.site_url("/settings/user?dept=" + dept._id + ":" + escape(dept.name)) }')
                | รายชื่อเจ้าหน้าที่
            .field.is-inline
              a.button.is-block(onclick="{ editDepartment(dept._id, dept.name) }")
                | แก้ไข

  .spacing
  .load-more-wrapper.has-text-centered(show='{ hasMore }')
    a.button.load-more(class='{ "is-loading": !loaded }', onclick='{ loadData }' ) Load More

  #edit-department-form.modal
    .modal-header
        h3 แก้ไขข้อมูลหน่วยงาน
    .divider
    .modal-content
      .field
        label.label ชื่อหน่วยงาน
        .control
          input.input(type="text", name="departmentName", value="{ editingDepartment && editingDepartment.name }")

    .modal-footer
      .row
        .col.s12
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(onclick="{closeEditDepartmentModal}") ยกเลิก
            .control
              a.button.is-outlined.is-accent(onclick="{confirmEditDepartment}") บันทึก

  #create-department-form(class="modal")
    .modal-header
      h3 สร้างหน่วยงานใหม่
    .modal-content
      .field
        label.label ชื่อหน่วยงาน
        .control
          input.input(type="text", name="name", placeholder="กายภาพ, กิจการนิสิต")

    .modal-footer
      .row
        .col.s12
          .field.is-grouped.is-pulled-right
            .control
              a.button.is-outlined(onclick="{closeCreateModal}") ยกเลิก
            .control
              a.button.is-outlined.is-accent(onclick="{confirmCreate}") สร้างหน่วยงาน

  script.
    let self = this;
    let $editModal, $createModal;

    self.departments  = [];
    self.hasMore = true;
    self.loaded = true;

    $(document).ready( () => {
      $editModal  = $('#edit-department-form').modal();
      $createModal = $('#create-department-form').modal();
    })

    self.on('mount', () => {
      self.loadData();
    });

    self.loadData = () => {
      const opts = { $skip: self.departments.length };
      self.loaded = false;
      api.getDepartments( opts ).then( result => {
        self.loaded = true;
        self.departments = self.departments.concat(result.data)
        self.updateHasMoreButton(result);
        self.update();
      });
    };

    self.updateHasMoreButton = (result) => {
      self.hasMore = ( result.total - ( result.skip + result.data.length ) ) > 0;
    }

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
          self.closeCreateModal();
          self.loadData();
        })
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      );
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
        self.closeEditDepartmentModal();
        self.loadData();
        location.reload();
      })
      .catch(err =>
        Materialize.toast(err.message, 8000, 'dialog-error large')
      );
    };
