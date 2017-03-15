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

  .spacing

  .big-number-table(show='{ category_list.length > 0 }')
    .columns(each='{ row in category_row }')
      .column.is-3.has-text-centered(each='{ c in row }')
        div
          p.heading { c.name }
          p.title
            span.success-number { c.resolved }
            span / { c.total }
          p Rejected: { c.rejected }

  .spacing

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
            //- th.pending.has-text-right Pending
            th.assigned.has-text-right Assigned
            th.processing.has-text-right Processing
            th.resolved.has-text-right Resolved
            th.rejected.has-text-right Rejected
            th.performance.has-text-right Performance Index

          tr.row(each="{data}", class="{ hide: shouldHideRow(department._id) }")
            td.team { name }
            //- td.numeric-col { summary.pending || 0}
            td.numeric-col { summary.assigned || 0}
            td.numeric-col { summary.processing || 0}
            td.numeric-col { summary.resolved || 0}
            td.numeric-col { summary.rejected || 0}
            td.performance(class="{  positive: performance > 0, negative: performance < 0 }")
              | {  performance.toFixed(2) }


  script.
    let self = this;

    self.picker = {};
    self.date = {
      from: moment().subtract(30, 'days').format('YYYY-MM-DD'),
      to: moment().format('YYYY-MM-DD')
    };
    self.data = [];
    self.departments = [];
    self.category_list = [];

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
        user.department_name = _.get(dept.data.filter(d => d._id === user.department), '0.name', '');
        self.departments = dept.data || [];
        _.sortBy(self.departments, ['name', '_id']);
        self.departments.push({
          _id: '1234',
          name: 'None'
        });
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
        api.getSummary( start_date, end_date, (data) => {
          available_departments = Object.keys(data);
          attributes = available_departments.length > 0 ? Object.keys( data[available_departments[0]] ) : [];

          return Promise.all(self.departments)
          .map(dept => {
            const name = dept.name;
            dept.summary = (data[name]) ? data[name].total : attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {});
            return dept;
          })
          .map(sum => api.getPerformance(self.date.from, self.date.to, sum._id)
            .then(result => {
              if (result.prev_active_pins + result.current_new_pins === 0) {
                sum.performance = 0.0;
              } else {
                sum.performance = result.current_resolved_pin / (result.prev_active_pins + result.current_new_pins);
              }
              return sum;
            })
          )
          .then(result => {
            summaries = result;
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

    self.changePeriod = (e) => {
      self.period = +e.currentTarget.value;
      self.loadData();
    };

    self.loadCategoryCount = (queryOpts = {}) => {
      const cats = app.get('issue.categories') || [];
      Promise.map( cats, cat => {
        let opts = _.extend(
          {},
          queryOpts,
          {
            '$limit': 1,
            //- is_archived: false,
            categories: cat.value
          }
        );

        return api.getPins(opts).then( res => {
          return {
            id: cat.value,
            name: cat.text,
            total: res.total,
            resolved: 0,
            rejected: 0
          }
        })
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
