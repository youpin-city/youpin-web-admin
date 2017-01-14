/* global util app user api Materialize*/

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
        'on ' + new Date(d.date).toLocaleDateString() + '</p></div></div>');
        // '<p>' + d.name + ' on ' + d.date.toLocaleDateString() + '</p></div></div>');
    }

    function modalClose(modal, trigger) {
      location.hash = '';
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
          $reporter.find('a.btn-flat').attr('href', 'mailto:' + owner.email);

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

          // Populate department dropdown list
          const $select_department = $select.eq(1);
          api.getDepartments()
          .then(departments => {
            $select_department.append('<option value="">[Please select]</option>');
            departments.data.forEach(department => {
              $select_department.append('<option value="' + department._id + '">' +
                department.name + '</option>');
            });
            if (data.assigned_department !== undefined && data.assigned_department !== '') {
              $select_department.val(data.assigned_department);
            }
            $select_department.material_select();
          });

          // update progress feed UI
          data.progresses.forEach((progress) =>
            prependProgressCard({
              date: progress.created_time,
              description: progress.detail,
              url: progress.photos[0]
            })
          );

          // Init Materialize
          $('.slider').slider({ height: $('.slider img').width() });
          $('.slider').slider('pause');
          $('.materialboxed').materialbox();

          // Buttons
          $('#cancel').click(() => {
            $('#manage-issue-modal').modal('close');
          });
          $('#confirm').click(() => {
            const body = {
              owner: user._id,
              detail: $details.find('textarea').val(),
              categories: $chips.eq(0).material_chip('data').map(d => d.tag),
              location: {
                coordinates: $chips.eq(1).material_chip('data').map(d => d.tag),
                type: 'Point'
              },
              tags: $chips.eq(2).material_chip('data').map(d => d.tag),
              assigned_department: $select_department.val()
            };
            /* $select.eq(0).val(data.status.priority);
            $status.find('textarea').val(data.status.annotation)*/

            // Edit pin info (partially)
            api.patchPin(id, body)
            .then(response => response.json())
            .then(() => $('#manage-issue-modal').modal('close'))
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );
          });

          const $archive = $('#archive');
          if (user.is_superuser && (data.status === 'rejected' || data.status === 'resolved')) {
            $archive.show();
          } else {
            $archive.hide();
          }
          $archive.click(() => {
            api.patchPin(id, {
              is_archived: true
            })
            .then(response => response.json())
            .then(() => $('#manage-issue-modal').modal('close'))
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );
          });

          const $reject = $('#reject');
          if ((user.is_superuser && (data.status === 'unverified' || data.status === 'verified')) ||
              (!user.is_superuser && data.status === 'assigned')) {
            $reject.show();
          } else {
            $reject.hide();
          }
          $reject.click(() => {
            api.postTransition(id, {
              state: 'rejected'
            })
            .then(response => response.json())
            .then(() => $('#manage-issue-modal').modal('close'))
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );
          });

          $('#goToNextState')
            .text(() => {
              switch (data.status) {
                case 'unverified':
                  return 'Verify';
                case 'verified':
                  return 'Assign';
                case 'assigned':
                  return user.is_superuser ? 'Process' : 'Accept';
                case 'processing':
                  return 'Resolve';
                case 'resolved':
                  return 'Process';
                default:
                  return 'Recover';
              }
            })
            .click(() => {
              let body;
              switch (data.status) {
                case 'unverified':
                default:
                  body = {
                    state: 'verified'
                  };
                  break;
                case 'verified':
                  body = {
                    state: 'assigned',
                    assigned_department: $select_department.val()
                  };
                  break;
                case 'assigned':
                case 'resolved':
                  body = {
                    state: 'processing',
                    processed_by: user._id
                  };
                  break;
                case 'processing':
                  body = {
                    state: 'resolved'
                  };
                  break;
              }

              if (data.status === 'verified' && $select_department.val() === '') {
                Materialize.toast('Please select a department', 8000, 'dialog-error large');
              } else {
                api.postTransition(id, body)
                .then(response => response.json())
                .then(() => $('#manage-issue-modal').modal('close'))
                .catch(err => {
                  Materialize.toast(err.message, 8000, 'dialog-error large');
                });
              }
            });
          $('#post').click(() => {
            const $progress = $('#progress');
            const files = $progress.find('input[type="file"]')[0].files;
            if (files.length > 0) {
              const progressData = {
                photos: [
                  window.URL.createObjectURL(files[0])
                ],
                detail: $progress.find('textarea').val()
              };

              // update progress feed UI
              prependProgressCard({
                date: new Date(),
                description: progressData.detail,
                url: progressData.photos[0]
              });
              $('.materialboxed').materialbox();

              // Edit pin info (partially)
              const form = new FormData();
              fetch(progressData.photos[0])
              .then(response => response.blob())
              .then(blob => {
                form.append('image', blob);
                api.postPhoto(form)
                .then(response => response.json())
                .then(photo_data => {
                  progressData.photos[0] = photo_data.url;
                  api.patchPin(id, {
                    owner: user._id,
                    $push: { progresses: progressData }
                  })
                  // .then(response => response.json())
                  .catch(err =>
                    Materialize.toast(err.message, 8000, 'dialog-error large')
                  );
                });
              });
            }
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
      $select.eq(0).val(data.status.priority);
      $status.find('textarea')
        .val(data.status.annotation)
        .trigger('autoresize');

      // Init Materialize
      $('.modal').modal({
        ready: ready,
        complete: modalClose
      });
      $('select').material_select();
    });
  }
};
