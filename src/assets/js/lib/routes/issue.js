/* global util app user Materialize Console*/

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
          if (data.status === 'pending') { // only cannot set back to 'pending' from other statuses
            $select.eq(0).append('<option value="pending">Pending</option>');
          }
          $select.eq(0)
            .append('<option value="unassigned">Unassigned</option>')
            .append('<option value="assigned">Assigned</option>')
            .append('<option value="processing">Processing</option>')
            .append('<option value="resolved">Resolved</option>')
            .append('<option value="rejected">Rejected</option>')
            .append('<option value="duplicated">Duplicated</option>')
            .val(data.status);

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
            // TODO Save data
            const bodyState = {
              detail: $details.find('textarea').val(),
              categories: $chips.eq(0).material_chip('data').map(d => d.tag),
              location: {
                coordinates: $chips.eq(1).material_chip('data').map(d => d.tag)
              },
              tags: $chips.eq(2).material_chip('data').map(d => d.tag)
            };
            /* $select.eq(1).val(data.status.priority);
            $status.find('textarea').val(data.status.annotation)*/

            // Edit pin info (partially)
            fetch(util.site_url('/pins/' + id, app.config.api_url), {
              method: 'PATCH',
              body: bodyState,
              headers: {
                'Content-type': 'application/json',
                Authorization: 'Bearer ' + user.token
              }
            })
            .then(response => response.json())
            .then(() => $('#manage-issue-modal').modal('close'))
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );

            // State transition
            fetch(util.site_url('/pins/' + id + 'state_transition', app.config.api_url), {
              method: 'POST',
              body: {
                state: $select.eq(0).val(data.status),
                assigned_department: $select.eq(2).val(data.status.department)
              },
              headers: {
                Accept: 'application/json',
                'Content-Type': 'application/json',
                Authorization: 'Bearer ' + user.token
              }
            })
            .then(response => response.json())
            .then(() => $('#manage-issue-modal').modal('close'))
            .catch(err =>
              Materialize.toast(err.message, 8000, 'dialog-error large')
            );
          });
          $('#reject').click(() => {
            // TODO Save data
            fetch(util.site_url('/pins/' + id + 'state_transition', app.config.api_url), {
              method: 'POST',
              body: {
                state: 'unassigned'
              },
              headers: {
                Accept: 'application/json',
                'Content-Type': 'application/json',
                Authorization: 'Bearer ' + user.token
              }
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
              // TODO save data
              let bodyState;
              switch (data.status) {
                case 'processing':
                  bodyState = { state: 'resolved' };
                  break;
                default:
                  bodyState = {
                    state: 'assigned',
                    assigned_department: '' // TODO get current user's department
                  };
                  break;
              }
              fetch(util.site_url('/pins/' + id + 'state_transition', app.config.api_url), {
                method: 'POST',
                body: bodyState,
                headers: {
                  Accept: 'application/json',
                  'Content-Type': 'application/json',
                  Authorization: 'Bearer ' + user.token
                }
              })
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
            prependProgressCard({
              name: '#{user_name}',
              date: new Date(),
              description: progressData.detail,
              url: progressData.photos[0]
            });
            $('.materialboxed').materialbox();

            // TODO save data
            // Edit pin info (partially)
            fetch(util.site_url('/pins/' + id, app.config.api_url), {
              method: 'PATCH',
              body: {
                progresses: progressData
              },
              headers: {
                'Content-type': 'application/json',
                Authorization: 'Bearer ' + user.token
              }
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
      progress: [
        {
          name: 'Thiti',
          date: new Date(),
          description: 'update 1',
          url: 'https://youpin-asset-test.s3-ap-southeast-1.amazonaws.com/f994c4f9d8748bd688a3f288b982ada53342447d84a045d114ce925255363bfd.png'
        },
        {
          name: 'Luang',
          date: new Date(),
          description: 'update 2',
          url: 'https://youpin-asset-test.s3-ap-southeast-1.amazonaws.com/fad08f3e311dfdd721fc476a329a7dbf37847d782feb036da730f35738813a6c.png'
        }
      ],
      status: {
        status: 'processing',
        priority: 'normal',
        department: 'departmentC',
        annotation: 'test'
      }
    }).then(data => {
      const $status = $('#status');
      const $select = $status.find('select');
      $select.eq(1).val(data.status.priority);
      $select.eq(2).val(data.status.department);
      $status.find('textarea')
        .val(data.status.annotation)
        .trigger('autoresize');

      data.progress.forEach(prependProgressCard);

      // Init Materialize
      $('.modal').modal({
        ready: ready
      });
      $('select').material_select();
    });
  }
};
