issue-page
  //- div.bt-new-issue.right
  //-   a.button.is-accent(href='#create-issue-modal') Create New Issue
  //- h1.page-title
  //-   | เรื่องร้องเรียน
  //- ul.status-selector
  //-   li(each="{statuses}", class="{active: name == selectedStatus}", onclick="{parent.select(name)}")
  //-     | {name}
  //-     span.badge.new(data-badge-caption='') {totalIssues}

  nav.level.is-mobile
    .level-left
      .level-item
        .title เรื่องร้องเรียน
      .level-item
        .control(style='width: 140px;')
          input(type='text', id='select_status', ref='select_status', placeholder='แสดงตามสถานะ')

      .level-item
        .control(style='width: 140px;')
          input(type='text', id='select_department', ref='select_department', placeholder='แสดงตามหน่วยงาน')

      .level-item
        .control(style='width: 140px;')
          input(type='text', id='select_staff', ref='select_staff', placeholder='แสดงตามเจ้าหน้าที่')

    .level-right
      .level-item
        .control(style='width: 140px;')
          input(type='text', id='select_sort', ref='select_sort', placeholder='เรียง')

      .level-item
        .control
          .bt-new-issue.right
            a.button.is-accent(href='#create-issue-modal') Create New Issue

  issue-list

  .modal#create-issue-modal.issue-view-modal
    .modal-header
      .row
        .col.s6
          h3 Create Issue
        .col.s6.right-align
          a.btn#create Create
      .row
        .col.s12
          p
          .divider
    .modal-content
      .row
        .col.s6.l9.main-content
          .row
            .col.s12.l6
              #photo
                .file-field.input-field
                  input(type='file', accept="image/*")
                  .file-path-wrapper
                    input.file-path.validate(type="text", placeholder="Click to upload photo")
            .col.s12.l6
              #details
                h5 Description
                .input-field.control
                  textarea.input
                h5 Category
                .chips.chips-initial
                //- h5 Location
                //- .chips.chips-initial
                h5 Tag
                .chips.chips-initial
        .col.s6.l3#status
          h5 Priority
          .input-field
            select.browser-default
              option(value='urgent') Urgent
              option(value='normal') Normal
              option(value='trivial') Trivial
          #select-department
            h5 Department
            .input-field
              select.browser-default
          h5 Annotation
          .input-field.control
            textarea.input

  script.
    let self = this;

    this.statusesForRole = []

    let queryOpts = {};

    //- if( user.role == 'super_admin' || user.role == 'organization_admin' ) {
    //-   this.statusesForRole =  ['pending', 'assigned', 'processing', 'resolved', 'rejected'];
    //- } else {
    //-   this.statusesForRole =  ['assigned', 'processing', 'resolved'];
    //-   queryOpts['assigned_department'] = user.department;
    //- }

    this.statuses = [];
    this.selectedStatus = this.statusesForRole[0];

    //- function getStatusesCount() {
    //-   Promise.map( self.statusesForRole, status => {
    //-     // get no. issues per status
    //-     let opts = _.extend(
    //-       {},
    //-       queryOpts,
    //-       {
    //-         '$limit': 1,
    //-         //- is_archived: false,
    //-         status: status
    //-       }
    //-     );

    //-     return api.getPins(opts).then( res => {
    //-       return {
    //-         name: status,
    //-         totalIssues: res.total
    //-       }
    //-     })
    //-   })
    //-   .then( data => {
    //-     self.statuses = data;
    //-     self.update();
    //-     self.select(self.statuses[0].name)();
    //-   });
    //- }
    //- getStatusesCount();

    this.select = (status) => {
      return () => {
        self.selectedStatus = status;

        let query = _.extend({
          //- status: status,
          //- is_archived: false
        }, queryOpts );

        self.tags['issue-list'].load(query);
      }
    }

    $(document).ready(() => {
      const $modal = $('#create-issue-modal');
      $modal.modal();

      const $details = $('#details');
      $details.find('textarea')
        .val('')
        .trigger('autoresize');

      $('.chips').material_chip({
        placeholder: 'Enter a tag',
        secondaryPlaceholder: 'Enter a tag'
      });
      const $chips = $details.find('.chips-initial');

      // Department selection for superuser
      var $select_department;
      if (user.is_superuser) {
        $select_department = $('#status').find('select').eq(1);
        $select_department.empty();
        $select_department.append('<option value="">[Please select]</option>');

        // Populate department dropdown list
        api.getDepartments()
        .then(departments => {
          departments.data.forEach(department => {
            $select_department.append('<option value="' + department._id + '">' +
              department.name + '</option>');
          });
          $select_department.material_select();
        });
      } else {
        $modal.find('#select-department').hide();
      }

      $('.materialboxed').materialbox();
      $('select').material_select();

      $('#create').click(() => {
        // check required data fields
        const files = $('#photo').find('input[type="file"]')[0].files;
        const detail = $details.find('textarea').val();
        const department = user.department || $select_department.val();
        if (files.length <= 0 || detail.length <= 0) {
          Materialize.toast('Photo and description are required.', 8000, 'dialog-error large')
        } else if (user.is_superuser && department === '') {
          Materialize.toast('Please select a department', 8000, 'dialog-error large')
        } else {
          // upload photo first
          fetch(window.URL.createObjectURL(files[0]))
          .then(response => response.blob())
          .then(blob => {
            const form = new FormData();
            form.append('image', blob);
            api.postPhoto(form)
            .then(response => response.json())
            .then(photo_data => {
              const current_time = Date.now();
              var location = $chips.eq(1).material_chip('data');
              location = {
                  coordinates: (location.length < 2) ? [0, 0] : [location[0].tag, location[1].tag],
                  types: 'Point'
                }
              const body = {
                provider: user._id,
                owner: user._id,
                detail: detail,
                photos: [photo_data.url],

                categories: $chips.eq(0).material_chip('data').map(d => d.tag),
                tags: $chips.eq(2).material_chip('data').map(d => d.tag),
                location: location,

                created_time: current_time,
                updated_time: current_time,

                status: 'assigned',
                assigned_department: department,
                organization: '583ddb7a3db23914407f9b50'
              };
              /* $select.eq(0).val(data.status.priority);
              $status.find('textarea').val(data.status.annotation) */

              // Create pin
              api.createPin(body)
              .then(response => response.json())
              .then(() => $('#create-issue-modal').modal('close'))
              .catch(err =>
                Materialize.toast(err.message, 8000, 'dialog-error large')
              );
            });
          });
        }
      });

    });

    self.current_filter = {};
    self.current_sort = '-updated_time';

    self.on('before-mount', () => {
      //- self.id = self.opts.dataId;
    });

    self.on('mount', () => {
      //- self.loadPin();
      //- self.bindEvents();
      self.initSelectStatus();
      self.initSelectDepartment();
      self.initSelectStaff();
      self.initSelectSort();

      self.loadPinByFilter();
    });

    self.loadPinByFilter = () => {
      let query = _.merge({}, self.current_filter, {
        $sort: self.current_sort
      });
      console.log('pin by:', query);
      self.tags['issue-list'].load(query);
    };

    self.initSelectStatus = () => {
      const status = [
        { id: 'all', name: 'สถานะทั้งหมด' },
        { id: 'open', name: 'เปิด' },
        { id: 'closed', name: 'ปิด' },
        //- { id: 'resolved', name: 'ปิดและแก้ไขสำเร็จ' },
        //- { id: 'rejected', name: 'ปิดและไม่แก้ไข' },
        //- { id: 'spam', name: 'ปิดและสเปม' }
      ];
      $(self.refs.select_status).selectize({
        maxItems: 1,
        valueField: 'id',
        labelField: 'name',
        //- searchField: 'name',
        options: _.compact(status), // all choices
        items: ['all'], // selected choices
        create: false,
        allowEmptyOption: false,
        //- hideSelected: true,
        //- preload: true,
        onChange: function(value) {
          //- const filter = _.find(status, ['id', value]);
          delete self.current_filter.status;
          delete self.current_filter.closed_reason;

          switch (value) {
            case 'all':
              break;
            case 'open':
              self.current_filter.status = { $in: ['pending', 'assigned', 'processing'] };
              break;
            case 'closed':
              self.current_filter.status = { $in: ['resolved', 'rejected'] };
              break;
            case 'resolved':
              self.current_filter.status = 'resolved';
              break;
            case 'rejected':
              self.current_filter.status = 'rejected';
              self.current_filter.closed_reason = 'rejected';
              break;
            case 'spam':
              self.current_filter.status = { $in: ['resolved', 'rejected'] };
              self.current_filter.closed_reason = 'spam';
              break;
          }

          self.loadPinByFilter();
        }
      });
    }

    self.initSelectDepartment = () => {
      const status = [
        { _id: 'all', name: 'หน่วยงานทั้งหมด' }
      ];
      $(self.refs.select_department).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        //- searchField: 'name',
        options: _.compact(status), // all choices
        items: ['all'], // selected choices
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
          delete self.current_filter.assigned_department;
          if (value && value !== 'all') {
            self.current_filter.assigned_department = value;
          }
          console.log(self.current_filter, 'filter dept');
          self.loadPinByFilter();
        }
      });
    }

    self.initSelectStaff = () => {
      const status = [
        { _id: 'all', name: 'เจ้าหน้าที่ทั้งหมด' }
      ];
      $(self.refs.select_staff).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        //- searchField: 'name',
        options: _.compact(status), // all choices
        items: ['all'], // selected choices
        create: false,
        allowEmptyOption: false,
        //- hideSelected: true,
        preload: true,
        load: function(query, callback) {
          //- if (!query.length) return callback();
          api.getUsers({})
          .then(result => {
            callback(result.data);
          });
        },
        onChange: function(value) {
          delete self.current_filter.assigned_users;
          if (value && value !== 'all') {
            self.current_filter.assigned_users = value;
          }
          console.log(self.current_filter, 'filter staff');
          self.loadPinByFilter();
        }
      });
    }

    self.initSelectSort= () => {
      const status = [
        { id: '-updated_time', name: 'อัพเดทล่าสุด' },
        { id: 'updated_time', name: 'อัพเดทเก่าสุด' },
        { id: '-created_time', name: 'วันที่รายงานล่าสุด' },
        { id: 'created_time', name: 'วันที่รายงานเก่าสุด' },
        { id: '-level', name: 'ความสำคัญสูง' },
        { id: 'level', name: 'ความสำคัญต่ำ' }
      ];
      $(self.refs.select_sort).selectize({
        maxItems: 1,
        valueField: 'id',
        labelField: 'name',
        options: _.compact(status), // all choices
        items: ['-updated_time'], // selected choices
        create: false,
        allowEmptyOption: false,
        onChange: function(value) {
          self.current_sort = value;
          self.loadPinByFilter();
        }
      });
    }
