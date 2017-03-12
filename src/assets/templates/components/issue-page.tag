issue-page
  div.bt-new-issue.right
    a.btn(href='#create-issue-modal') Create New Issue
  h1.page-title
    | Issue
  ul.status-selector
    li(each="{statuses}", class="{active: name == selectedStatus}", onclick="{parent.select(name)}")
      | {name}
      span.badge.new(data-badge-caption='') {totalIssues}

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
                    input.file-path.validate(type="text", placeholder="Upload photo")
            .col.s12.l6
              #details
                h5 Description
                .input-field
                  textarea.materialize-textarea
                h5 Category
                .chips.chips-initial
                h5 Location
                .chips.chips-initial
                h5 Tag
                .chips.chips-initial
        .col.s6.l3#status
          h5 Priority
          .input-field
            select
              option(value='urgent') Urgent
              option(value='normal') Normal
              option(value='trivial') Trivial
          #select-department
            h5 Department
            .input-field
              select
          h5 Annotation
          .input-field
            textarea.materialize-textarea

  script.
    let self = this;

    this.statusesForRole = []

    let queryOpts = {};

    if( user.role == 'super_admin' || user.role == 'organization_admin' ) {
      this.statusesForRole =  ['pending', 'assigned', 'processing', 'resolved', 'rejected'];
    } else {
      this.statusesForRole =  ['assigned', 'processing', 'resolved'];
      queryOpts['assigned_department'] = user.department;
    }

    this.statuses = [];
    this.selectedStatus = this.statusesForRole[0];

    function getStatusesCount() {
      Promise.map( self.statusesForRole, status => {
        // get no. issues per status
        let opts = _.extend(
          {},
          queryOpts,
          {
            '$limit': 1,
            is_archived: false,
            status: status
          }
        );

        return api.getPins(opts).then( res => {
          return {
            name: status,
            totalIssues: res.total
          }
        })
      })
      .then( data => {
        self.statuses = data;
        self.update();
        self.select(self.statuses[0].name)();
      });
    }
    getStatusesCount();

    this.select = (status) => {
      return () => {
        self.selectedStatus = status;

        let query = _.extend({
          status: status,
          is_archived: false
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

      // Department seleciton for superuser
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
