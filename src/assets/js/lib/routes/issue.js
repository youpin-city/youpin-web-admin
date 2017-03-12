/* global util _ app user api Materialize*/

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
        (d.url ? '<img class="materialboxed" src=' + d.url + '></div>' : '') +
        '<div class="card-content"><p>' + d.description + '</p>' +
        'on ' + new Date(d.date).toLocaleDateString() + '</p></div></div>');
        // '<p>' + d.name + ' on ' + d.date.toLocaleDateString() + '</p></div></div>');
    }

    function modalClose(modal, trigger) {
      const $modal = $('#manage-issue-modal');
      location.hash = '';
      $modal.find('.slider .slides').empty();
      $modal.find('#cards').empty();
      $('.btn-flat, .btn').unbind('click');
    }

    function ready(modal, trigger) {
      const $modal = $('#manage-issue-modal');
      const id = modal[0].baseURI.split('#!issue-id:')[1]; // trigger.attr('data-id');
      $('#id').text(id);
      api.getPin(id)
      .then(data => {
        const owner = _.get(data, 'owner');
        data.photos.forEach(d =>
          $modal.find('.slider .slides')
            .append('<li><img class="materialboxed" src=' + d + '></li>')
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

        // Dropdown lists
        const $status = $('#status');
        const $select = $status.find('select');
        const $select_department = $select.eq(1); // Department OR department officer
        $select_department.empty();
        $select_department.append('<option value="">[Please select]</option>');

        if (user.is_superuser) {
          // Populate department dropdown list
          api.getDepartments()
          .then(departments => {
            departments.data.forEach(department => {
              $select_department.append('<option value="' + department._id + '">' +
                department.name + '</option>');
            });
            if (data.assigned_department !== undefined && data.assigned_department !== '') {
              $select_department.val(data.assigned_department._id);
            }
            $select_department.material_select();
          });
          $modal.find('#status').show();
        } else if (user.role === 'department_head') {
          // Populate department officer dropdown list
          api.getUsers({ role: 'department_officer', department: user.department })
          .then(users => {
            users.data.forEach(user => {
              $select_department.append('<option value="' + user._id + '">' +
                user.name + '</option>');
            });
            if (data.assigned_users !== undefined && data.assigned_users.length > 0) {
              $select_department.val(data.assigned_users[0]._id);
            }
            $select_department.material_select();
          });

          // Disable admin UI elements
          $chips.find('i').remove();
          $chips.find('input')
            .attr('placeholder', '')
            .prop('disabled', true);
          $status.find('input')
            .prop('disabled', true);
          $modal.find('#status').show();
        } else {
          $modal.find('#status').hide();
        }

        if (['department_head', 'department_officer'].indexOf(user.role) >= 0) {
          // update progress feed UI
          data.progresses.forEach((progress) =>
            prependProgressCard({
              date: progress.created_time,
              description: progress.detail,
              url: progress.photos[0]
            })
          );
        }

        // Init Materialize
        $('.slider').slider({ height: $('.slider img').width() });
        $('.slider').slider('pause');
        $('.materialboxed').materialbox();
        $('select').material_select();

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
        if (user.is_superuser && !data.is_archived
                              && (data.status === 'rejected' || data.status === 'resolved')) {
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
        if ((user.is_superuser && (data.status === 'pending')) ||
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
        // Merge Issues Button
        if (data.is_merged) {
          $('#merge-issue-btn')
          .hide();
        } else {
          $('#merge-issue-btn')
          .attr('href', util.site_url('merge/') + data._id)
          .show();
        }

        if (data.is_merged) {
          $('#merged-parent').show();
          $('#merged-parent ul.list').empty();
          if (data.merged_parent_pin) {
            $('#merged-parent ul.list').append(
              $('<li/>').append(
                $('<a/>')
                .attr('href', '#!issue-id:' + data.merged_parent_pin)
                .append('<i class="icon material-icons tiny">bookmark</i>')
                .append('<span>Main Issue</span>')
              )
            );
          }
        } else {
          $('#merged-parent').hide();
          $('#merged-parent ul.list').empty();
        }
        if ((data.merged_children_pins || []).length > 0) {
          $('#merged-children').show();
          $('#merged-children ul.list').empty();
          _.forEach(data.merged_children_pins || [], pin_id => {
            $('#merged-children ul.list').append(
              $('<li/>').append(
                $('<a/>')
                .attr('href', '#!issue-id:' + pin_id)
                .append('<i class="icon material-icons tiny">bookmark</i>')
                .append('<span>Issue:' + pin_id + '</span>')
              )
            );
          });
        } else {
          $('#merged-children').hide();
          $('#merged-children ul.list').empty();
        }

        // Next State Button
        $('#goToNextState')
          .text(() => {
            switch (data.status) {
              case 'pending':
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
              case 'pending':
                body = {
                  state: 'assigned',
                  assigned_department: $select_department.val()
                };
                break;
              case 'assigned':
              case 'resolved':
                body = {
                  state: 'processing',
                  processed_by: $select_department.val(),
                  assigned_users: [$select_department.val()]
                };
                break;
              case 'processing':
              default:
                body = {
                  state: 'resolved'
                };
                break;
            }

            if (data.status === 'pending' && $select_department.val() === '') {
              Materialize.toast('Please select a department', 8000, 'dialog-error large');
            } else if (data.status === 'assigned' && $select_department.val() === '') {
              Materialize.toast('Please select a department officer', 8000, 'dialog-error large');
            } else {
              api.postTransition(id, body)
              .then(response => response.json())
              .then(() => $('#manage-issue-modal').modal('close'))
              .catch(err => {
                Materialize.toast(err.message, 8000, 'dialog-error large');
              });
            }
          });

        // Area to update issue progress
        const $progress = $('#progress');
        // Disable progress if the issue is not accepted
        const isAssigned = (data.status === 'assigned');
        $progress.find('textarea, input').prop('disabled', isAssigned);
        $progress.find('a').toggleClass('disabled', isAssigned);
        // Set Post button event
        $('#post').click(() => {
          const files = $progress.find('input[type="file"]')[0].files;
          const progress_text = $progress.find('textarea').val();
          if (files.length === 0 && !progress_text) {
            return;
          }
          const progressData = {
            photos: files.length > 0
              ? [window.URL.createObjectURL(files[0])]
              : [],
            detail: progress_text
          };

          // update progress feed UI
          prependProgressCard({
            date: new Date(),
            description: progressData.detail,
            url: progressData.photos[0]
          });
          $('.materialboxed').materialbox();

          // Edit pin info (partially)
          if (files.length > 0) {
            // upload photo first, if any
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
                .then(response => {
                  $progress.find('textarea').val('');
                  $progress.find('input[type="file"]').val('');
                })
                .catch(err =>
                  Materialize.toast(err.message, 8000, 'dialog-error large')
                );
              });
            });
          } else {
            // post without photo
            api.patchPin(id, {
              owner: user._id,
              $push: { progresses: progressData }
            })
            .then(response => {
              $progress.find('textarea').val('');
            })
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );
          }
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
