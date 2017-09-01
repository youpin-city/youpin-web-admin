report-department-page
  .container
    .report-tool.opaque-bg
      .breadcrumb
        span
          strong Report
      h1.page-title
        span Department
        span(hide='{ can_choose_department }') : { user && user.dept && user.dept.name}
        .field.is-inline(show='{ can_choose_department }', style='vertical-align: middle;')
          .control(style='width: 200px;')
            input(type='text', id='select_department', ref='select_department', placeholder='แสดงตามหน่วยงาน')

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
              th.assigned(style='width: 120px;')
                .has-text-right เปิด
              th.resolved(style='width: 120px;')
                .has-text-right แก้ไขสำเร็จ
              th.rejected(style='width: 120px;')
                .has-text-right ปิดกรณีอื่น
              th.performance(style='width: 120px;')
                .has-text-right Performance Index

            tr(each="{row in data_by_user}")
              td.name
                a(href='/issue?staff={row.id}:{row.name}') { row.name }
              td.numeric-col { row.count.open || 0}
              td.numeric-col { row.count.resolved || 0}
              td.numeric-col { row.count.rejected || 0}
              td.numeric-col.performance(class="{  positive: row.performance > 0, negative: row.performance < 0 }") { row.performance.toFixed(2) }

  script.
    const self = this;

    self.picker = {};
    self.date = {
      from: moment().subtract(30, 'days').format('YYYY-MM-DD'),
      to: moment().format('YYYY-MM-DD')
    };
    self.data_by_user = [];
    self.officers = [];
    self.department_id = user.dept._id;
    self.can_choose_department = util.check_permission('view_department', user.role);
    self.is_loading = false;

    self.on('mount', () => {
      self.initSelectDepartment();

      self.setupCloseDateCalendar($(self.root).find('.date-from-picker'), 'from');
      self.setupCloseDateCalendar($(self.root).find('.date-to-picker'), 'to');
      self.loadDepartment()
      .then(() => self.loadData());
    });

    self.loadDepartment = () => {
      return api.getUsers({ department: self.department_id })
      .then(result => {
        self.officers = result.data || [];
      });
    };

    function computePerformance(performance_data) {
      if (performance_data.prev_active_pins + performance_data.current_new_pins === 0) {
        return 0.0;
      } else {
        return performance_data.current_resolved_pin / (performance_data.prev_active_pins + performance_data.current_new_pins);
      }
    }

    self.loadData = () => {
      self.is_loading = true;
      self.update();
      const start_date = self.date['from'];
      const end_date = self.date['to'];
      let summaries = [];
      let orgSummary = [];
      let total_performance_data = {
        current_resolved_pin: 0,
        prev_active_pins: 0,
        current_new_pins: 0
      };
      let attributes = [
        'pending',
        'assigned',
        'processing',
        'rejected',
        'resolved'
      ];
      return Promise.resolve({}).then(() =>
        api.getSummary( start_date, end_date, (status_table) => {
          return Promise.all(self.officers)
          .map(officer => {
            const dept_name = user.dept.name;
            const data_dept = status_table[dept_name];
            const data_officer = (data_dept && data_dept[officer.name]) ? data_dept[officer.name] : attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {});
            officer.id = officer._id;
            const name = officer.name;
            // set dept's count to status_table
            // or create zero table if dept is not in status_table
            if (data_dept && data_dept[dept_name]) {
              officer.count = data_dept[dept_name].total;
              // rename 'None' to 'Unassigned' for better readability
              //- if (!officer._id) officer.name = 'Unassigned';
            } else {
              officer.count = attributes.reduce((acc, cur) => {
                acc[cur] = 0;
                return acc;
              }, {});
            }
            return officer;
          })
          .map(sum => {
            if (!sum._id) {
              // Unassigned row
              sum.performance = 0;
              return sum;
            }
            // Department rows
            return api.getPerformance(self.date.from, self.date.to, { user: sum._id })
            .then(result => {
              // calculate performance of this department over this period
              sum.performance = computePerformance(result);
              // accumulate performance data
              total_performance_data.current_resolved_pin += result.current_resolved_pin || 0;
              total_performance_data.prev_active_pins += result.prev_active_pins || 0;
              total_performance_data.current_new_pins += result.current_new_pins || 0;
              return sum;
            });
          })
          .then(result => {
            summaries = result;
          });
        })
      )
      .then(() => {
        if (!user.is_superuser) return [];
        // for admin, calculate total from all departments
        let all = _.reduce( attributes, (acc,attr) => {
          acc[attr] = 0;
          return acc;
        }, {} );

        all = _.reduce(summaries, (acc, dept) => {
           _.each( attributes, attr => {
              acc[attr] += dept['count'][attr] || 0;
          });
          return acc;
        }, all);
        orgSummary = {
          name: 'All Users',
          count: all,
          performance: computePerformance(total_performance_data)
        };
        return [orgSummary];
      })
      .then(admin_summary => admin_summary.concat(summaries))
      .map(summary => {
        // calculate virtual 'open' status
        summary.count.open = summary.count.pending
          + summary.count.assigned
          + summary.count.processing;
        return summary;
      })
      .then(result => {
        self.data_by_user = result;
        self.is_loading = false;
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

    self.initSelectDepartment = () => {
      const status = [
        { _id: user.dept._id, name: user.dept.name }
      ];
      $(self.refs.select_department).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        searchField: 'name',
        options: _.compact(status), // all choices
        items: [user.dept._id], // selected choices
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
          self.department_id = value;
          self.loadDepartment();
        }
      });
    }
