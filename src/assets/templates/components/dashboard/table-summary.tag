dashboard-table-summary
  h1.page-title Overview
  table.summary
    tr
      th.team Team
      th.assigned Assigned
      th.processing Processing
      th.resolved Resolved
      th.rejected Rejected
      th.performance Performance Index

    tr.row(each="{data}")
      td.team { name }
      td.numeric-col { assigned }
      td.numeric-col { processing }
      td.numeric-col { resolved }
      td.numeric-col { rejected }
      td.performance(class="{  positive: performance > 0, negative: performance < 0 }") {  performance }

  script.
    this.data = [
        { name:'Department A', assigned: 10, processing: 2, resolved: 5, rejected: 3, performance: 2 },
        { name:'Department B', assigned: 5, processing: 1, resolved: 0, rejected: 0,  performance: -4 },
        { name:'Department C', assigned: 5, processing: 5, resolved: 0, rejected: 0,  performance: 0 }
    ]
