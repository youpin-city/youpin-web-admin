dashboard-recent-activity
  div.recent-activity
    b Recent Activity
    ul
      li(each="{data}").activity
        img(src="{img}")
        span
            b { activity } </br>
            | { username } / { department } / { ts }


  script.
    this.data = [
      { img: 'http://lorempixel.com/50/50/cats/', activity: 'closed issue A', username: 'john', department: 'dept. a', ts: '1h ago' },
      { img: 'http://lorempixel.com/50/50/cats/', activity: 'rejected issue B', username: 'john', department: 'dept. b', ts: '1.5h ago' }
    ]
