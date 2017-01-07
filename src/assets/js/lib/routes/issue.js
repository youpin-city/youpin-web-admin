/* global util app user api Materialize Console*/

const modalId = '#manage-issue-modal';
const dataKey = ' issue-id';

const issueRouter = module.exports = {
  process: (issueId) => {
    $(modalId).data(dataKey, issueId);
    $(modalId).trigger('openModal');
  },
  setup: () => {
    function prependProgressCard(d) {
      $('#cards').prepend('<div class="card"><div class="card-image">' +
        '<img class="materialboxed" src=' + d.url + '></div>' +
        '<div class="card-content"><p>' + d.description + '</p>' +
        '<p>' + d.name + ' on ' + d.date.toLocaleDateString() + '</p></div></div>');
    }

    function ready(modal, trigger) {
      const id = modal[0].baseURI.split('#!issue-id:')[1]; // trigger.attr('data-id');
      $('#id').text(id);
      fetch(util.site_url('/pins/' + id, app.config.api_url), {
        method: 'GET'
      })
      .then(response => response.json())
      .then(data => {
        fetch(util.site_url('/users/' + data.owner, app.config.api_url), {
          method: 'GET',
          headers: {
            'Content-type': 'application/json',
            Authorization: 'Bearer ' + user.token
          }
        })
        .then(response => response.json())
        .then(owner => {
          data.photos.forEach(d =>
            $('.slides').append('<li><img class="materialboxed" src=' + d + '></li>')
          );

          const $reporter = $('#reporter');
          const $span = $reporter.find('span');
          $span.eq(0).text(owner.name);
          $span.eq(1).text((new Date(data.created_time)).toLocaleDateString());
          $reporter.find('a.btn-flat').attr('href', 'mailto:' + data.owner);

          const $details = $('#details');
          $details.find('textarea')
            .val(data.detail)
            .trigger('autoresize');

          $('.chips').material_chip({
            placeholder: 'Enter a tag',
            secondaryPlaceholder: 'Enter a tag'
          });

          const $chips = $details.find('.chips-initial');
          $chips.eq(0).material_chip({ data: data.categories.map(d => ({ tag: d })) });
          $chips.eq(1).material_chip({ data: data.location.coordinates.map(d => ({ tag: d })) });
          $chips.eq(2).material_chip({ data: data.tags.map(d => ({ tag: d })) });

          // Disable chips aka tags when the user role is of a department
          if (user.is_superuser !== true) {
            $chips.find('i').remove();
            $chips.find('input')
              .attr('placeholder', '')
              .prop('disabled', true);
          }

          // Dropdown lists
          const $status = $('#status');
          const $select = $status.find('select');

          // Populate status dropdown list
          const $select_status = $select.eq(0);
          if (data.status === 'unverified') { // cannot set back to 'unverified' from other statuses
            $select_status.append('<option value="unverified">Unverified</option>');
          }
          $select_status
            // .append('<option value="unverified">Unverified</option>')
            .append('<option value="verified">Verified</option>')
            .append('<option value="assigned">Assigned</option>')
            .append('<option value="processing">Processing</option>')
            .append('<option value="resolved">Resolved</option>')
            .append('<option value="rejected">Rejected</option>')
            .append('<option value="duplicated">Duplicated</option>')
            .val(data.status)
            .material_select();

          // Populate department dropdown list
          const $select_department = $select.eq(2);
          api.getDepartments()
          .then(departments => {
            departments.data.forEach(department => {
              $select_department.append('<option value="' + department._id + '">' +
                department.name + '</option>');
            });
            $select_department
              .val(data.assigned_department)
              .material_select();
          });

          // Init Materialize
          $('.slider').slider({ height: $('.slider img').width() });
          $('.slider').slider('pause');
          $('.materialboxed').materialbox();

          // Buttons
          /* $('#reset').click(function() {
          });*/
          $('#cancel').click(() => {
            $('#manage-issue-modal').modal('close');
          });
          $('#confirm').click(() => {
            const body = {
              owner: user._id,
              detail: $details.find('textarea').val(),
              categories: $chips.eq(0).material_chip('data').map(d => d.tag),
              location: {
                coordinates: $chips.eq(1).material_chip('data').map(d => d.tag)
              },
              tags: $chips.eq(2).material_chip('data').map(d => d.tag)
            };
            const new_state = $select.eq(0).val();
            switch (new_state) {
              case 'assigned':
                body.assigned_department = $select.eq(2).val();
                break;
              case 'processing':
                body.processed_by = user._id;
                break;
              default:
                break;
            }
            /* $select.eq(1).val(data.status.priority);
            $status.find('textarea').val(data.status.annotation)*/

            // Edit pin info (partially)
            api.patchPin(id, body)
            .then(response => response.json())
            .then(() => $('#manage-issue-modal').modal('close'))
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );

            // State transition
            if (data.status !== new_state) {
              const body_transition = {
                state: new_state
              };
              switch (new_state) {
                case 'assigned':
                  body_transition.assigned_department = body.assigned_department;
                  break;
                case 'processing':
                  body_transition.processed_by = body.processed_by;
                  break;
                default:
                  break;
              }
              api.postTransition(id, body_transition)
              .then(response => response.json())
              .then(() => $('#manage-issue-modal').modal('close'))
              .catch(err =>
                Materialize.toast(err.message, 8000, 'dialog-error large')
              );
            }
          });
          $('#reject').click(() => {
            api.postTransition(id, {
              state: 'verified'
            })
            .then(response => response.json())
            .then(() => $('#manage-issue-modal').modal('close'))
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );
          });
          $('#acceptOrResolve')
            .text(() => {
              switch (data.status) {
                case 'processing':
                  return 'Resolve';
                default:
                  return 'Accept';
              }
            })
            .click(() => {
              let body;
              switch (data.status) {
                case 'processing':
                  body = {
                    state: 'resolved'
                  };
                  break;
                default:
                  body = {
                    state: 'processing',
                    processed_by: user._id
                  };
                  break;
              }

              api.postTransition(id, body)
              .then(response => response.json())
              .then(() => $('#manage-issue-modal').modal('close'))
              .catch(err =>
                Materialize.toast(err.message, 8000, 'dialog-error large')
              );
            });
          $('#post').click(() => {
            const $progress = $('#progress');
            const progressData = {
              photos: [
                window.URL.createObjectURL($progress.find('input[type="file"]')[0].files[0])
              ],
              detail: $progress.find('textarea').val()
            };
            data.progresses.push(progressData);

            // update progress feed UI
            prependProgressCard({
              name: user.name,
              date: new Date(),
              description: progressData.detail,
              url: progressData.photos[0]
            });
            $('.materialboxed').materialbox();

            // Edit pin info (partially)
            api.patchPin(id, {
              owner: user._id,
              progresses: data.progresses
            })
            .then(response => response.json())
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );
          });
        });
      });
    }

    return Promise.resolve({
      status: {
        priority: 'normal',
        annotation: ''
      }
    }).then(data => {
      const $status = $('#status');
      const $select = $status.find('select');
      $select.eq(1).val(data.status.priority);
      $status.find('textarea')
        .val(data.status.annotation)
        .trigger('autoresize');

      // Init Materialize
      $('.modal').modal({
        ready: ready
      });
      $('select').material_select();
    });
  }
};
