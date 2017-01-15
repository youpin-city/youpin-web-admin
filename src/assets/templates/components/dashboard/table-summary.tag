dashboard-table-summary
  h1.page-title Overview
  ul.duration-selector
    li(each="{ dur, i in durationSelectors}", class="{ highlight: activeSelector == i }", onclick="{ selectDuration(i) }", title="{dur.start}-today")
        div {dur.name}

  table.summary
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
    let ymd = 'YYYY-MM-DD';
    let end_date = moment().add(1,'day').format(ymd);

    self.activeSelector = 0;

    this.durationSelectors = [
      { name: 'week', start: generateStartDate('week', 'day', 1) },
      { name: '1 months', start: generateStartDate('month', 'month', 0) },
      { name: '2 months', start: generateStartDate('month', 'month', -1) },
      { name: '6 months', start: generateStartDate('month', 'month', -5) }
    ];

    this.selectDuration  = function(selectorIdx) {
      return function(){
        self.activeSelector = selectorIdx;

        let start_date = self.durationSelectors[selectorIdx].start;

        api.getDepartments()
        .then(departments => {
          departments = departments.data.map(d => d.name);
          api.getSummary( start_date, end_date, (data) => {
            let available_departments = Object.keys(data);
            let attributes = available_departments.length > 0 ? Object.keys( data[available_departments[0]] ) : [];

            let deptSummaries = _.map( departments, dept => {
              const data_dept = (data[dept] === undefined) ? attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {}) : data[dept];
              return {
                name: dept,
                summary: data_dept,
                performance: computePerformance(attributes, data_dept)
              }
            });

            let all = _.reduce( attributes, (acc,attr) => {
              acc[attr] = 0;
              return acc;
            }, {} );

            all = _.reduce( deptSummaries, (acc, dept) => {
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

            self.data = [ orgSummary ].concat(deptSummaries);

            self.update();
          });
        });
      }
    }

    // Initialize selector
    this.selectDuration(0)();

    function generateStartDate(period, adjPeriod, unit ){
        return moment().isoWeekday(1).startOf(period).add(unit,adjPeriod).format(ymd);
    }

    function computePerformance( attributes, summary){
      let total = _.reduce( attributes, (acc, attr) => {
          acc += (summary[attr] || 0);
          return acc;
        }, 0);
      console.log(summary);
      console.log(total);
      let divider = total - ((summary.unverified || 0 ) + (summary.rejected || 0 ));
      if( divider === 0 ) {
        return 0;
      }
      console.log(divider);
      return (summary.resolved || 0) / divider;
    }

    this.shouldHideRow = function(department){
        return user.role != "organization_admin" && user.department != department;
    }
