dashboard-table-summary
  h1.page-title Overview

  #big-number-table.opaque-bg(show='{ status_list.length > 0 }')
    .level
      .level-item.has-text-centered(each='{ s in status_list }')
        div
          p.heading { s.name }
          p.title { s.count }

  .spacing

  div.performance-table.opaque-bg
    ul.duration-selector.clearfix
      li(each="{ dur, i in durationSelectors}", class="{ highlight: activeSelector == i }", onclick="{ selectDuration(i) }", title="{dur.start}-today")
          div {dur.name}

    div.date-range
      label ระยะเวลา
      span ตั้งแต่ { date.from } ถึง { date.to }
      span(show='{ is_loading }')
        loading-icon
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

      tr(each="{row in data_by_department}", class="{ hide: shouldHideRow(row._id) }")
        td.team { row.name }
        td.numeric-col { row.count.open || 0}
        td.numeric-col { row.count.resolved || 0}
        td.numeric-col { row.count.rejected || 0}
        td.numeric-col.performance(class="{  positive: row.performance > 0, negative: row.performance < 0 }") { row.performance.toFixed(2) }

  script.
    const self = this;
    const ymd = 'YYYY-MM-DD';
    self.date = {
      from: moment().add(-1, 'week').add(1, 'day').format('YYYY-MM-DD'),
      to: moment().format('YYYY-MM-DD')
    };
    self.data_by_department = [];
    self.is_loading = false;
    self.status_list = [];
    self.activeSelector = 0;
    self.durationSelectors = [
      { name: 'This Week', start: generateStartDate(1, 'week') },
      { name: 'Last 1 Month', start: generateStartDate(1, 'month') },
      { name: 'Last 2 Months', start: generateStartDate(2, 'month') },
      { name: 'Last 6 Months', start: generateStartDate(6, 'month') }
    ];

    self.on('mount', () => {
      // Initialize selector
      self.loadDepartment()
      .then(() => self.setDateRange(0));

      self.loadStatusCount();
    });

    function generateStartDate(unit, period) {
      return moment().add(-unit, period).add(1, 'day').format(ymd);
    }
    //- function generateStartDate(period, unit, adjPeriod) {
    //-   return moment().isoWeekday(1).startOf(period).add(unit, adjPeriod).format(ymd);
    //- }

    self.setDateRange = function (index) {
      self.date['from'] = self.durationSelectors[index].start;
      self.date['to'] = moment().format('YYYY-MM-DD'); // moment().add(1, 'day').format('YYYY-MM-DD')
      self.loadData();
    }

    self.selectDuration = function (selectorIdx) {
      return function (e) {
        self.activeSelector = selectorIdx;
        self.setDateRange(selectorIdx);
      }
    }

    self.loadDepartment = () => {
      let dept;
      return api.getDepartments()
      .then(result => {
        dept = result;
        return api.getUsers((user.department) ? { department: user.department } : undefined)
      })
      .then(result => {
        self.departments = dept.data || [];
        _.sortBy(self.departments, ['name', '_id']);
        // create unassign row
        self.departments = [{
          _id: '',
          name: 'None'
        }].concat(self.departments);
      });
    }

    self.shouldHideRow = function(department) {
      return !util.check_permission('supervisor', user.role)
        && user.department != department;
    }

    function computePerformance(performance_data) {
      if (performance_data.prev_active_pins + performance_data.current_new_pins === 0) {
        return 0.0;
      } else {
        return performance_data.current_resolved_pin / (performance_data.prev_active_pins + performance_data.current_new_pins);
      }
    }

    self.loadData = () => {
      self.is_loading = true;
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
          return Promise.all(self.departments)
          .map(dept => {
            const name = dept.name;
            // set dept's count to status_table
            // or create zero table if dept is not in status_table
            if (status_table[name]) {
              dept.count = status_table[name].total;
              // rename 'None' to 'Unassigned' for better readability
              //- if (!dept._id) dept.name = 'Unassigned'; // Bug
            } else {
              dept.count = attributes.reduce((acc, cur) => {
                acc[cur] = 0;
                return acc;
              }, {});
            }
            return dept;
          })
          .map(sum => {
            if (!sum._id) {
              // Unassigned row
              sum.performance = 0;
              return sum;
            }
            // Department rows
            return api.getPerformance(self.date.from, self.date.to, { department: sum._id })
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
          name: 'All Departments',
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
        self.data_by_department = result;
        self.is_loading = false;
        self.update();
      });
    };

    self.loadStatusCount = (queryOpts = {}) => {
      const status_keys = [
        'pending',
        'assigned',
        'processing'
      ];
      Promise.map( status_keys, status => {
        let opts = _.extend(
          {},
          queryOpts,
          {
            '$limit': 1,
            status: status
          }
        );

        return api.getPins(opts).then( res => {
          return {
            name: status,
            count: res.total
          }
        })
      })
      .then( data => {
        self.status_list = data || [];
        self.update();
      });
    };
