loading-icon
  span.svg-content(ref='svg-content')
  script.
    var self = this;
    self.on('mount', function() {
      $.get('/public/img/loader.svg')
      .done(function(data) {
        self.refs['svg-content'].innerHTML = data.documentElement.outerHTML;
      });
    });