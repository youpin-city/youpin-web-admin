report-department-page
  .container
    .report-tool.opaque-bg
      .breadcrumb
        span
          strong Report
      h1.page-title Department
        | : { user && user.dept && user.dept.name}
      h3.section-title แสดงตามช่วงเวลา
        | {moment(date['from']).format('DD/MM/YYYY')}
        | -
        | {moment(date['to']).format('DD/MM/YYYY')}

      .level
        .level-left
          .level-item
            div
              label.label ตั้งแต่
              .control
                .date-from-picker
                input.input(type='text', name='date_from', value='{ date["from"] }')
          .level-item
            div
              label.label ถึง
              .control
                .date-to-picker
                input.input(type='text', name='date_to', value='{ date["to"] }')

    .spacing-small

    .section.opaque-bg
      h3.section-title เรื่องแยกตามเจ้าหน้าที่
      .columns
        .column
          table.table.is-striped.is-narrow.performance-summary
            tr
              th.team Team
              //- th.pending.has-text-right Pending
              //- th.assigned.has-text-right Assigned
              th.assigned.has-text-right(style='width: 120px;') เปิด
              th.resolved.has-text-right(style='width: 120px;') แก้ไขสำเร็จ
              th.rejected.has-text-right(style='width: 120px;') ปิดกรณีอื่น
              th.performance.has-text-right(style='width: 120px;') Performance Index

            tr(each="{ data }", class="{ hide: shouldHideRow(department._id) }")
              td.name
                //- .is-pulled-right
                //-   a(href='{ util.site_url("/issue?user=" + _id + ":" + name) }') ดูเรื่องที่รับผิดชอบ
                profile-image.is-round.is-small(name='{ name }')
              //- td.team { name }
              //- td.numeric-col { summary.pending || 0}
              //- td.numeric-col { summary.assigned || 0}
              td.numeric-col { _.sum(_.pick(summary, ['pending', 'assigned', 'processing'])) || 0}
              td.numeric-col { summary.resolved || 0 }
              td.numeric-col { summary.rejected || 0 }
              td.numeric-col.performance(class="{  positive: performance > 0, negative: performance < 0 }") { performance.toFixed(2) }

  script.
    let self = this;

    self.picker = {};
    self.date = {
      from: moment().subtract(30, 'days').format('YYYY-MM-DD'),
      to: moment().format('YYYY-MM-DD')
    };
    self.data = [];
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

      let summaries = [];
      let orgSummary = [];
      let available_departments = [];
      let attributes = [];

      return Promise.resolve({})
      .then(() =>
        api.getPerformance(self.date.from, self.date.to)
        .then(result => {
          console.log('Perf:', result);
        })
      )
      .then(() =>
        api.getSummary( start_date, end_date, (data) => {
          available_departments = Object.keys(data);
          attributes = available_departments.length > 0 ? Object.keys( data[available_departments[0]] ) : [];

          // Officer summary
          summaries = _.map( self.officers, officer => {
            const data_dept = data[user.dept.name];
            const data_officer = (data_dept && data_dept[officer.name]) ? data_dept[officer.name] : attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {});
            return {
              name: officer.name,
              summary: data_officer,
              performance: computePerformance(attributes, data_officer)
            }
          });

        })
      )
      .then(() => {
        let all = _.reduce( attributes, (acc,attr) => {
          acc[attr] = 0;
          return acc;
        }, {} );

        all = _.reduce( summaries, (acc, dept) => {
           _.each( attributes, attr => {
              acc[attr] += dept['summary'][attr] || 0;
          });
          return acc;
        }, all);

        orgSummary = {
          name: 'All',
          summary: all,
          performance: computePerformance(attributes, all)
        };
      })
      .then(() => {
        self.data = user.is_superuser ? [ orgSummary ] : [];
        self.data = self.data.concat(summaries);

        self.update();
      });
    };

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
