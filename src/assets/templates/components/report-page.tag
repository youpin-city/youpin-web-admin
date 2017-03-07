report-page
  .breadcrumb
    span
      strong Report
  h1.page-title Performance Index

  .report-tool
    .level.is-mobile
      .level-left
        .level-item
          div
            label.label From
            .control
              .date-from-picker
              input.input(type='text', name='date_from', value='{ date["from"] }')
        .level-item
          div
            label.label To
            .control
              .date-to-picker
              input.input(type='text', name='date_to', value='{ date["to"] }')
  .spacing-small

  .section
    .columns
      .column
        h3.page-title Show data between
          | {moment(date['from']).format('DD/MM/YYYY')}
          | -
          | {moment(date['to']).format('DD/MM/YYYY')}

        table.performance-summary
          tr
            th.team Team
            th.pending Pending
            th.assigned Assigned
            th.processing Processing
            th.resolved Resolved
            th.rejected Rejected
            th.performance Performance Index

          tr.row(each="{data}", class="{ hide: shouldHideRow(department._id) }")
            td.team { name }
            td.numeric-col { summary.pending || 0}
            td.numeric-col { summary.assigned || 0}
            td.numeric-col { summary.processing || 0}
            td.numeric-col { summary.resolved || 0}
            td.numeric-col { summary.rejected || 0}
            td.performance(class="{  positive: performance > 0, negative: performance < 0 }") {  performance.toFixed(2) }


  script.
    let self = this;

    self.picker = {};
    self.date = {
      from: moment().subtract(7, 'days').format('YYYY-MM-DD'),
      to: moment().format('YYYY-MM-DD')
    };
    self.data = [];
    self.departments = [];
    self.officers = [];

    self.on('mount', () => {
      self.setupCloseDateCalendar($(self.root).find('.date-from-picker'), 'from');
      self.setupCloseDateCalendar($(self.root).find('.date-to-picker'), 'to');
      self.loadDepartment()
      .then(() => self.loadData());
    });

    self.loadDepartment = () => {
      let dept;
      return api.getDepartments()
      .then(result => {
        dept = result;
        return api.getUsers((user.department) ? { department: user.department } : undefined) // role: 'department_officer',
      })
      .then(result => {
        self.officers = result.data || [];
        user.department_name = _.get(dept.data.filter(d => d._id === user.department), '0.name', '');

        self.departments = dept.data.map(d => d.name);
        self.departments.sort(); // Sort department by name.
        self.departments.push('None'); // Add 'None' departments for non-assigned pins
      });
    }

    self.loadData = () => {

      function computePerformance( attributes, summary){
        let total = _.reduce( attributes, (acc, attr) => {
            acc += (summary[attr] || 0);
            return acc;
          }, 0);

        let divider = total - ((summary.pending || 0 ) + (summary.rejected || 0 ));
        if( divider === 0 ) {
          return 0;
        }

        return (summary.resolved || 0) / divider;
      }

      const start_date = self.date['from'];
      const end_date = self.date['to'];

      api.getSummary( start_date, end_date, (data) => {
        let available_departments = Object.keys(data);
        let attributes = available_departments.length > 0 ? Object.keys( data[available_departments[0]] ) : [];

        let summaries = [];
        if (user.is_superuser) { // Department summary
          summaries = _.map( self.departments, dept => {
            const data_dept = (data[dept]) ? data[dept].total : attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {});
            return {
              name: dept,
              summary: data_dept,
              performance: computePerformance(attributes, data_dept)
            }
          });
        } else { // Officer summary
          summaries = _.map( self.officers, officer => {
            const data_dept = data[user.department_name];
            const data_officer = (data_dept && data_dept[officer.name]) ? data_dept[officer.name] : attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {});
            return {
              name: officer.name,
              summary: data_officer,
              performance: computePerformance(attributes, data_officer)
            }
          });
        }

        let all = _.reduce( attributes, (acc,attr) => {
          acc[attr] = 0;
          return acc;
        }, {} );

        all = _.reduce( summaries, (acc, dept) => {
           _.each( attributes, attr => {
              acc[attr] += dept['summary'][attr];
          });
          return acc;
        }, all);

        let orgSummary = {
          name: 'All',
          summary: all,
          performance: computePerformance(attributes, all)
        };

        self.data = user.is_superuser ? [ orgSummary ] : [];
        self.data = self.data.concat(summaries);

        self.update();
      });
    }

    self.destroyCloseDateCalendar = function() {
      if (self.picker.length === 0) return;
      _.forEach(self.picker, picker => {
        $(window).off('resize.' + picker.__id);
        picker.destroy();
      });
      self.picker = [];
    }
    self.setupCloseDateCalendar = function(calendar, name) {
      if (self.picker[name]) return;
      var this_year = moment().format('YYYY');
      var $calendar = $(calendar);
      var $input = $calendar.next('input');
      self.picker[name] = new Pikaday({
        field: $input.get(0),
        format: 'YYYY-MM-DD',
        numberOfMonths: 1,
        showDaysInNextAndPreviousMonths: true,
        yearRange: [+this_year, +this_year+1],
        // minDate: moment().toDate(),
        maxDate: moment().toDate(),
        onSelect: function(date) {
          self.date[name] = moment(date).format('YYYY-MM-DD');
          self.loadData();
        },
      });
      self.picker[name].__id = util.uniqueId('calendar-');
      $(window).on('resize.' + self.picker[name].__id, function() {
        self.picker[name].adjustPosition();
      });
    };