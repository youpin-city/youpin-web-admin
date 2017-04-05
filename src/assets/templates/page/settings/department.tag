setting-department
  nav.level.is-mobile.is-wrap
    .level-left
      .level-item
        .title หน่วยงาน
      //- .level-item
      //-   .control(style='width: 140px;')
      //-     input(type='text', id='select_department', ref='select_department', placeholder='แสดงตามหน่วยงาน')

    .level-right
      .level-item
        .control
          a.button.is-accent(onclick="{ createDepartment }")
            | สร้างหน่วยงาน

  .opaque-bg.content-padding.is-overflow-auto
    table.table.is-striped
      thead
        tr
          th หน่วยงาน
      tbody
        tr(each="{dept in departments}" ).department
          td
            .department-media.media
              .media-left
                profile-image.is-round-box(name='{ dept.name }')
              .media-right
                a.is-plain(id='row-menu-btn-{ dept._id }', href='#')
                  i.icon.material-icons more_horiz
                dropdown-menu(target='#row-menu-btn-{ dept._id }', position='bottom right', menu='{ row_menu_list(dept) }')

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
    const self = this;

    self.departments  = [];
    self.hasMore = true;
    self.loaded = true;

    self.row_menu_list = (dept) => () => [
      {
        id: 'list-dept-user-btn-' + dept._id,
        name: 'รายชื่อเจ้าหน้าที่',
        url: util.site_url("/settings/user?dept=" + dept._id + ":" + escape(dept.name)),
        target: '',
      },
      {
        id: 'edit-dept-btn-' + dept._id,
        name: 'แก้ไข',
        url: '#',
        target: '',
        onclick: (e) => { self.editDepartment(dept._id, dept.name)(); }
      }
    ];

    $(document).ready( () => {
    })

    self.on('mount', () => {
      self.$editModal  = $('#edit-department-form').modal();
      self.$createModal = $('#create-department-form').modal();
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
        let $modal = self.$editModal;
        self.editingDepartment = {
          id: deptId,
          name: deptName,
        }
        self.update();
        $modal.trigger('openModal');
      }
    }

    self.createDepartment = () => {
      let $modal = self.$createModal;

      let $input = $modal.find('input[name="name"]');
      $input.val('');

      $modal.trigger('openModal');
    }

    self.closeCreateModal = () => {
      let $modal = self.$createModal;
      $modal.trigger('closeModal');
    }

    self.confirmCreate = () => {
      let $modal = self.$createModal;
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
      let $modal = self.$editModal;
      $modal.trigger('closeModal');
    };

    self.confirmEditDepartment = () => {
      const patch = {
        name: self.$editModal.find('input[name="departmentName"]').val(),
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
