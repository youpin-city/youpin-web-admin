
const modalId = '#manage-issue-modal';
const dataKey = ' issue-id';

const issueRouter = module.exports = {
    process: (issueId) => {
        $(modalId).data( dataKey, issueId)
        $(modalId).trigger('openModal');
    },
    setup: () => {
          function prependProgressCard(d) {
            $('#cards').prepend('<div class="card"><div class="card-image">'+
              '<img class="materialboxed" src='+d.url+'></div>'+
              '<div class="card-content"><p>'+d.description+'</p>'+
              '<p>'+d.name+' on '+d.date.toLocaleDateString()+'</p></div></div>');
          }

          function ready(modal, trigger) {
            let id = $(modal).data(dataKey);

            fetch(util.site_url('/pins/'+id, app.config.api_url), {
              method: 'GET'
            })
            .then(function(response) {
              return response.json();
            })
            .then(function(data) {

              $('.slides').empty();
              (data.photos || []).forEach( function(d) {
                $('.slides').append('<li><img class="materialboxed" src='+d+'></li>');
              });

              var $reporter = $('#reporter');
              var $span = $reporter.find('span');
              $span.eq(0).text(data.owner); //TODO owner's name
              $span.eq(1).text((new Date(data.created_time)).toLocaleDateString());
              $reporter.find('a.btn-flat').attr('href', 'mailto:'+data.owner);

              var $details = $('#details');
              $details.find('textarea')
                .val(data.detail)
                .trigger('autoresize');

              $('.chips').material_chip({
                placeholder: 'Enter a tag',
                secondaryPlaceholder: 'Enter a tag'
              });

              var $chips = $details.find('.chips-initial');
              $chips.eq(0).material_chip({data: data.categories.map(function(d) { return {tag: d}; })});
              $chips.eq(1).material_chip({data: data.location.coordinates.map(function(d) { return {tag: d}; })});
              $chips.eq(2).material_chip({data: data.tags.map(function(d) { return {tag: d}; })});

              //Disable chips aka tags when the user role is of a department
              if('#{superuser}' !== 'true') {
                $chips.find('i').remove();
                $chips.find('input')
                  .attr('placeholder', '')
                  .prop('disabled', true);
              }

              //Init Materialize
              $('.slider').slider({ height: $('.slider img').width() });
              $('.slider').slider('pause');
              $('.materialboxed').materialbox();

              //Buttons
              /*$('#reset').click(function() {
              });*/
              $('#cancel').click(function() {
                $('#manage-issue-modal').modal('close');
              });
              $('#confirm').click(function() {
                //TODO save data
                $('.chips-initial').each( function() {
                  console.log($(this).material_chip('data').map(function(d) {
                    return d.tag;
                  }));
                });
                $('#manage-issue-modal').modal('close');
              });
              $('#reject').click(function() {
                fetch(util.site_url('/pins/'+id+'state_transition', app.config.api_url), {
                  method: 'POST',
                  body: {
                    state: "unassigned"
                  },
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json'
                  }
                })
                .then(function(response) {
                  return response.json();
                })
                .then(function(data) {
                  $('#manage-issue-modal').modal('close');
                })
                .catch(function(err) {
                  Materialize.toast(err.message, 8000, 'dialog-error large');
                });
              });
              $('#acceptOrResolve')
                .text(function() {
                  switch(data.status.status) {
                    case 'processing':
                      return 'Resolve';
                    case "assigned":
                    default:
                      return 'Accept';
                  }
                })
                .click(function() {
                  var bodyState;
                  switch(data.status.status) {
                    case 'processing':
                      bodyState = {state: "resolved"};
                      break;
                    case "assigned":
                    default:
                      bodyState = {status: "processing"};
                      break;
                  }
                  fetch(util.site_url('/pins/'+id+'state_transition', app.config.api_url), {
                    method: 'POST',
                    body: bodyState,
                    headers: {
                      'Accept': 'application/json',
                      'Content-Type': 'application/json'
                    }
                  })
                  .then(function(response) {
                    return response.json();
                  })
                  .then(function(data) {
                    $('#manage-issue-modal').modal('close');
                  })
                  .catch(function(err) {
                    Materialize.toast(err.message, 8000, 'dialog-error large');
                  });
                });
              $('#post').click(function() {
                //TODO save data
                var $progress = $('#progress');
                prependProgressCard({
                  name: '#{user_name}',
                  date: new Date(),
                  description: $progress.find('textarea').val(),
                  url: window.URL.createObjectURL($progress.find('input[type="file"]')[0].files[0])
                });
                $('.materialboxed').materialbox();
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
          }).then( function(data) {
            var $status = $('#status');
            var $select = $status.find('select');
            if(data.status.status === "pending") { //only cannot set back to 'pending' from other statuses
              $select.eq(0).append('<option value="pending">Pending</option>')
            }
            $select.eq(0)
              .append('<option value="unassigned">Unassigned</option>')
              .append('<option value="assigned">Assigned</option>')
              .append('<option value="processing">Processing</option>')
              .append('<option value="resolved">Resolved</option>')
              .append('<option value="rejected">Rejected</option>')
              .append('<option value="duplicated">Duplicated</option>')
              .val(data.status.status);
            $select.eq(1).val(data.status.priority);
            $select.eq(2).val(data.status.department);
            $status.find('textarea')
              .val(data.status.annotation)
              .trigger('autoresize');

            data.progress.forEach(prependProgressCard);

            //Init Materialize
            $(modalId).modal({
              ready: ready,
              complete: () => {
                window.location.hash = '!';
              }
            });

            $('select').material_select();
          });
    }
}
