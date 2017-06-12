report-page
  .container
    .report-tool.opaque-bg
      .breadcrumb
        span
          strong Report
      h1.page-title Performance
      h3.section-title แสดงตามช่วงเวลา
        | {moment(date['from']).format('DD/MM/YYYY')}
        | -
        | {moment(date['to']).format('DD/MM/YYYY')}
        span(show='{ is_loading }')
          loading-icon

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

    .spacing

    .section.opaque-bg
      h3.section-title เรื่องแยกตามสถานะ
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

            tr(each="{row in data_by_department}", class="{ hide: shouldHideRow(row._id) }")
              td.team { row.name }
              td.numeric-col { row.count.open || 0}
              td.numeric-col { row.count.resolved || 0}
              td.numeric-col { row.count.rejected || 0}
              td.numeric-col.performance(class="{  positive: row.performance > 0, negative: row.performance < 0 }") { row.performance.toFixed(2) }

    .spacing

    .section.opaque-bg(show='{ category_list.length > 0 }')
      h3.section-title แยกตามหมวด
      .big-number-table.category-table
        .columns(each='{ row in category_row }')
          .column.is-3.has-text-centered(each='{ c in row }')
            div
              .container.clearfix
                p.heading
                  strong { c.name }
              .container.clearfix
                p.subtitle.left ทั้งหมด
                p.title.has-text-right { c.total }
              .container.clearfix
                p.subtitle.left แก้ไขสำเร็จ
                p.title.has-text-right.success-number { c.resolved }
              .container.clearfix
                p.subtitle.left ปิดกรณีอื่น
                p.title.has-text-right.error-number { c.rejected }

  script.
    let self = this;

    self.picker = {};
    self.date = {
      from: moment().subtract(30, 'days').format('YYYY-MM-DD'),
      to: moment().format('YYYY-MM-DD')
    };
    self.data_by_department = [];
    self.departments = [];
    self.category_list = [];
    self.is_loading = false;

    self.on('mount', () => {
      self.loadCategoryCount();
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
      return false;
      //- return !util.check_permission('supervisor', user.role)
      //-   && user.department != department;
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
          return Promise.all(self.departments)
          .map(dept => {
            const name = dept.name;
            // set dept's count to status_table
            // or create zero table if dept is not in status_table
            if (status_table[name]) {
              dept.count = status_table[name].total;
              // rename 'None' to 'Unassigned' for better readability
              if (!dept._id) dept.name = 'Unassigned';
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
          self.loadCategoryCount();
        },
      });
      self.picker[name].__id = util.uniqueId('calendar-');
      $(window).on('resize.' + self.picker[name].__id, function() {
        self.picker[name].adjustPosition();
      });
    };

    self.loadCategoryCount = (queryOpts = {}) => {
      const cats = app.get('issue.categories') || [];
      Promise.map( cats, cat => {
        return api.getPerformance(self.date.from, self.date.to, { category: cat.id })
        .then(result => ({
          id: cat.id,
          name: cat.name,
          total: result.prev_active_pins + result.current_new_pins,
          resolved: result.current_resolved_pin,
          rejected: result.current_rejected_pin
        }));
      })
      .then( data => {
        self.category_list = data || [];
        self.category_row = [];
        const row = 4;
        for (let i=0; i<self.category_list.length / row; i++) {
          self.category_row.push(self.category_list.slice(i * row, (i + 1) * row));
        }
        self.update();
      });
    };
