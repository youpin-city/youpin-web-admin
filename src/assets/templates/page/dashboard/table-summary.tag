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
    ul.duration-selector
      li(each="{ dur, i in durationSelectors}", class="{ highlight: activeSelector == i }", onclick="{ selectDuration(i) }", title="{dur.start}-today")
          div {dur.name}

    table.table.is-striped.is-narrow.summary
      tr
        th.team Team
        //- th.pending.has-text-right Pending
        //- th.assigned.has-text-right Assigned
        //- th.processing.has-text-right Processing
        //- th.resolved.has-text-right Resolved
        //- th.rejected.has-text-right Rejected
        //- th.performance.has-text-right Performance Index
        th.assigned.has-text-right(style='width: 120px;') เปิด
        th.resolved.has-text-right(style='width: 120px;') แก้ไขสำเร็จ
        th.rejected.has-text-right(style='width: 120px;') ปิดกรณีอื่น
        th.performance.has-text-right(style='width: 120px;') Performance Index

      tr(each="{data}", class="{ hide: shouldHideRow(department._id) }")
        td.team { name }
        //- td.numeric-col { summary.pending || 0}
        //- td.numeric-col { summary.assigned || 0}
        //- td.numeric-col { summary.processing || 0}
        td.numeric-col { _.sum(_.pick(summary, ['pending', 'assigned', 'processing'])) || 0}
        td.numeric-col { summary.resolved || 0}
        td.numeric-col { summary.rejected || 0}
        td.numeric-col.performance(class="{  positive: performance > 0, negative: performance < 0 }") {  performance.toFixed(2) }

  script.

    let self = this;
    let ymd = 'YYYY-MM-DD';
    let end_date = moment().add(1,'day').format(ymd);

    self.status_list = [];
    self.activeSelector = 0;

    self.durationSelectors = [
      { name: 'week', start: generateStartDate('week', 'day', 1) },
      { name: '1 months', start: generateStartDate('month', 'month', 0) },
      { name: '2 months', start: generateStartDate('month', 'month', -1) },
      { name: '6 months', start: generateStartDate('month', 'month', -5) }
    ];

    self.on('mount', () => {
      // Initialize selector
      self.selectDuration(0)();
      self.loadStatusCount();
    });

    self.selectDuration = function(selectorIdx) {
      return function(){
        self.activeSelector = selectorIdx;

        let start_date = self.durationSelectors[selectorIdx].start;

        api.getDepartments()
        .then(departments => {
          api.getUsers((user.dept) ? { department: user.dept._id } : undefined) // role: 'department_officer',
          .then(officers => {
            departments = departments.data.map(d => d.name);
            departments.sort(); // Sort department by name.
            departments.push('None'); // Add 'None' departments for non-assigned pins

            api.getSummary( start_date, end_date, (data) => {
              let available_departments = Object.keys(data);
              let attributes = available_departments.length > 0 ? Object.keys( data[available_departments[0]] ) : [];

              let summaries = [];
              if (user.is_superuser) { // Department summary
                summaries = _.map( departments, dept => {
                  const data_dept = (data[dept]) ? data[dept].total : attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {});
                  return {
                    name: dept,
                    summary: data_dept,
                    performance: computePerformance(attributes, data_dept)
                  }
                });
              } else { // Officer summary
                summaries = _.map( officers.data, officer => {
                  const data_dept = data[user.dept.name];
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
          });
        });
      }
    }

    function generateStartDate(period, adjPeriod, unit ){
      return moment().isoWeekday(1).startOf(period).add(unit,adjPeriod).format(ymd);
    }

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

    this.shouldHideRow = function(department){
        return user.role != "organization_admin" && user.department != department;
    }

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
