dashboard-table-summary
  h1.page-title Overview
  ul.duration-selector
    li(each="{ dur, i in durationSelectors}", class="{ highlight: activeSelector == i }", onclick="{ selectDuration(i) }", title="{dur.start}-today")
        div {dur.name}

  table.summary
    tr
      th.team Team
      th.assigned Assigned
      th.processing Processing
      th.resolved Resolved
      th.rejected Rejected
      th.performance Performance Index

    tr.row(each="{data}", class="{ hide: shouldHideRow(department._id) }")
      td.team { name }
      td.numeric-col { summary.assigned }
      td.numeric-col { summary.processing }
      td.numeric-col { summary.resolved }
      td.numeric-col { summary.rejected }
      td.performance(class="{  positive: performance > 0, negative: performance < 0 }") {  performance }

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

        api.getSummary( start_date, end_date, (data) => {
          let departments = Object.keys(data);

          let attributes = Object.keys( data[departments[0]] );

          let deptSummaries = _.map( departments, dept => {
            return {
                name: dept,
                summary: data[dept],
                performance: computePerformance(attributes, data[dept])
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
      }
    }

    // Initialize selector
    this.selectDuration(0)();

    function generateStartDate(period, adjPeriod, unit ){
        return moment().isoWeekday(1).startOf(period).add(unit,adjPeriod).format(ymd);
    }

    function computePerformance( attributes, summary){
        let total = _.reduce( attributes, (acc,attr) => {
            acc += summary[attr];
            return acc;
          }, 0);

        let divider = total - (summary['unverified'] + summary['rejected']);
        if( divider == 0 ) {
          return 0;
        }

        return summary['resolved'] / divider;
    }

    this.shouldHideRow = function(department){
        return user.role != "organization_admin" && user.department != department;
    }
