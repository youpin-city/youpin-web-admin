dashboard-new-issue-list
  div.new-issue-list
    h1.page-title New issue this week
    ul
      li(each="{data}").item
        img(src="{img}")
        span
            b { description } </br>
            | { ts } / { status } / { department } / { priority }


  script.
    this.data = [
      { img: 'http://lorempixel.com/80/80/city/', description: 'broken pipe', ts: '1h ago', department: 'Dept A.', status: 'open', priority: 'high' },
      { img: 'http://lorempixel.com/80/80/city?sdf', description: 'broken door', ts: '1h ago', department: 'Dept B.', status: 'open', priority: 'high' }
    ]
