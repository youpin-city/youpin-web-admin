'use strict';

riot.tag2('dashboard-new-issue-list', '<div class="new-issue-list"> <h1 class="page-title">New issue this week</h1> <ul> <li class="item" each="{data}"><img riot-src="{photos[0]}"><span><b>{detail} </br></b>{created_time} / {status} / {assigned_department.name} / {level}</span></li> </ul> </div>', '', '', function (opts) {
  var self = this;
  self.data = [];

  api.getNewIssues(function (data) {
    self.data = _.map(data.data, function (d) {
      d.created_time = moment(d.created_time).fromNow();
      return d;
    });

    self.update();
  });
});

riot.tag2('dashboard-recent-activity', '<div class="recent-activity"><b>Recent Activity</b> <ul> <li class="activity" each="{data}"><span><b>{description} </br></b>{timestamp}</span></li> </ul> </div>', '', '', function (opts) {
  var self = this;
  self.data = [];

  api.getRecentActivities(function (data) {
    self.data = _.map(data, function (d) {
      d.timestamp = moment(d.timestamp).fromNow();
      return d;
    });

    self.update();
  });
});

riot.tag2('dashboard-table-summary', '<h1 class="page-title">Overview</h1> <ul class="duration-selector"> <li class="{highlight: activeSelector == i}" each="{dur, i in durationSelectors}" onclick="{selectDuration(i)}" title="{dur.start}-today"> <div>{dur.name}</div> </li> </ul> <table class="summary"> <tr> <th class="team">Team</th> <th class="assigned">Assigned</th> <th class="processing">Processing</th> <th class="resolved">Resolved</th> <th class="rejected">Rejected</th> <th class="performance">Performance Index</th> </tr> <tr class="row {hide: shouldHideRow(department._id)}" each="{data}"> <td class="team">{department.name} {}</td> <td class="numeric-col">{assigned}</td> <td class="numeric-col">{processing}</td> <td class="numeric-col">{resolved}</td> <td class="numeric-col">{rejected}</td> <td class="performance {positive: performance &gt; 0, negative: performance &lt; 0}">{performance}</td> </tr> </table>', '', '', function (opts) {
  var self = this;
  var ymd = "YYYY-MM-DD";
  var end_date = moment().format(ymd);

  self.activeSelector = 0;

  this.durationSelectors = [{ name: 'week', start: generateStartDate('week', 'day', 1) }, { name: '1 months', start: generateStartDate('month', 'month', 0) }, { name: '2 months', start: generateStartDate('month', 'month', -1) }, { name: '6 months', start: generateStartDate('month', 'month', -5) }];

  this.selectDuration = function (selectorIdx) {
    return function () {
      self.activeSelector = selectorIdx;

      var start_date = self.durationSelectors[selectorIdx].start;

      api.getSummary(user.organization, start_date, end_date, function (data) {
        var summary = (data.data || [])[0].by_department;

        summary = _.keyBy(summary, 'department.name');

        for (var i = 1; i < data.data.length; i++) {
          _.each(data.data[i].by_department, function (dep) {
            _.each(['resolved', 'processing', 'assigned'], function (k) {
              summary[dep.department.name][k] += dep[k];
            });
          });
        }

        self.data = _.map(summary, function (d) {
          d.performance = d.processing + d.resolved - d.assigned;
          return d;
        });

        self.update();
      });
    };
  };

  this.selectDuration(0)();

  function generateStartDate(period, adjPeriod, unit) {
    return moment().isoWeekday(1).startOf(period).add(unit, adjPeriod).format(ymd);
  }

  this.shouldHideRow = function (department) {
    return user.role != "organization_admin" && user.department != department;
  };
});

riot.tag2('image-slider', '<div class="slider-list"> <yield></yield> </div>', '', '', function (opts) {
  var self = this;
  self.item = opts.item || 'div';
  self.image = opts.image !== 'false';
  self.viewer = opts.viewer === 'true';
  self.arrows = !(opts.arrows === 'false');
  self.dots = opts.dots === 'true';
  self.autoplay = !(opts.autoplay === 'false');
  self.autoplay_speed = +(opts.autoplaySpeed || 12000);
  self.fade = !(opts.fade === 'false');

  self.extendClass = [];

  self.extendClass = self.extendClass.join(' ');

  self.on('mount', function () {

    self.$slider = $(self.root).find('.slider-list');

    self.$slider.children().show();
    self.$slider.on('init reinit', function (e) {
      if (self.image) {
        $(this).find('.slider-item').each(function () {
          var $item = $(this);
          var src = $item.attr('data-src');
          if (!src) {
            src = /url\(['"]?([^'"]*)['"]?\)/gi.exec($item.css('background-image'))[1];
          }
          $item.empty();
          if (self.item === 'img') {
            $item.append($('<img/>').addClass(self.extendClass).attr('data-src', src));
          } else {
            $item.append($('<div class="image hide-on-error"/>').addClass(self.extendClass).attr('data-src', src).css('background-image', 'url(\'' + src + '\')'));
          }
        });
      }
    }).on('setPosition', function (e, slick) {
      if (self.lazyload) {
        var i = slick.currentSlide;
        i = [i === 0 ? slick.$slides.length - 1 : i - 1, i, i === slick.$slides.length - 1 ? 0 : i + 1];
        var elements = _.compact($(slick.$slides[i[0]]).add(slick.$slides[i[1]]).add(slick.$slides[i[2]]).find('.lazyload:not(.lazyloaded)').toArray());
      }
    }).slick({
      infinite: true,
      speed: self.fade ? 1200 : 1200,
      fade: self.fade,
      autoplay: self.autoplay,
      autoplaySpeed: self.autoplay_speed,
      arrows: self.arrows,
      dots: self.dots,
      cssEase: 'ease-in'
    });

    if (self.viewer) {}
  });
});

riot.tag2('issue-page', '<h1 class="page-title">Issue <div class="bt-new-issue"><a class="btn" href="#manage-issue-modal">Create New Issue</a></div> </h1> <ul class="status-selector"> <li class="{active: name == selectedStatus}" each="{statuses}" onclick="{parent.select(name)}">{name}({issues})</li> </ul> <div class="menu-bar"> <div class="sorting">▾</div> <div class="list-or-map"><span class="active">List</span><span class="separator">/</span><span>Map</span></div> <div class="clearfix"></div> </div> <ul class="issue-list"> <li class="issue clearfix" each="{pins}"> <div class="issue-img"> <div class="img responsive-img" riot-style="background-image: url(&quot;{_.get(photos, &quot;0&quot;)}&quot;)"></div> </div> <div class="issue-body"> <div class="issue-id"><b>ID</b><span href="#manage-issue-modal" data-id="{_id}">{_id}</span> </div> <div class="issue-desc">{detail}</div> <div class="issue-category"> <div><b>Category</b><span class="bubble" each="{cat in categories}">{cat}</span></div> </div> <div class="issue-location"> <div><b>Location</b></div><span class="bubble">Building A</span> </div> <div class="clearfix"></div> <div class="issue-tags"> <div><b>Tag</b><span class="bubble" each="{tag in tags}">{tag}</span></div> </div> </div> <div class="issue-info"> <div><b>Status</b><span class="big-text">{status}</span> <div class="clearfix"></div> </div> <div><b>Dept.</b><span class="big-text">Engineer</span> <div class="clearfix"></div> </div> <div><b>Thiti Luang</b></div> <div>Submitted on {moment(created_time).fromNow()}</div><a class="bt-manage-issue btn" href="#manage-issue-modal" data-id="{_id}">Issue</a> </div> </li> </ul>', '', '', function (opts) {
  var self = this;
  this.all_pins = opts.pins || [];
  this.pins = this.all_pins;
  this.selectedStatus = 'pending';
  this.statuses = [{ name: 'pending', issues: 4 }, { name: 'assigned', issues: 5 }, { name: 'processing', issues: 2 }, { name: 'resolved', issues: 1 }];

  this.issues = _.range(0, this.statuses[0].issues);

  this.select = function (name) {
    return function () {
      self.selectedStatus = name;
      var statusIndex = _.findIndex(self.statuses, { name: name });
      self.issues = _.range(0, self.statuses[statusIndex].issues);
      self.pins = _.filter(self.all_pins, function (pin) {
        return pin.status === name;
      });
      this.update();
    };
  };
});

riot.tag2('preloader', '<div class="preloader-wrapper active {class}"> <div class="spinner-layer spinner-blue-only"> <div class="circle-clipper left"> <div class="circle"></div> </div> <div class="gap-patch"> <div class="circle"></div> </div> <div class="circle-clipper right"> <div class="circle"></div> </div> </div> </div>', '', '', function (opts) {
  var self = this;
  self.class = opts.class;
});

riot.tag2('search-box', '<a class="toggle-btn" href="#" onclick="{clickToggleSearch}"><i class="icon material-icons">search</i></a> <div class="search-box-wrapper" name="wrapper"> <form onsubmit="{submitSearch}"> <input class="flat" type="search" name="q" placeholder="{placeholder}" onblur="{clickToggleSearch}" tabindex="-1"> </form> </div>', 'search-box,[riot-tag="search-box"],[data-is="search-box"]{ display: inline-block; } search-box .toggle-btn,[riot-tag="search-box"] .toggle-btn,[data-is="search-box"] .toggle-btn{ display: inline-block; opacity: 1; transition: all 0.2s ease-out; } search-box .search-box-wrapper,[riot-tag="search-box"] .search-box-wrapper,[data-is="search-box"] .search-box-wrapper{ display: inline-block; width: 0; opacity: 0; padding-left: 0; padding-right: 0; transition: all 0.2s ease-out; } search-box.open .toggle-btn,[riot-tag="search-box"].open .toggle-btn,[data-is="search-box"].open .toggle-btn{ width: 0; opacity: 0; padding-left: 0; padding-right: 0; } search-box.open .search-box-wrapper,[riot-tag="search-box"].open .search-box-wrapper,[data-is="search-box"].open .search-box-wrapper{ width: 200px; opacity: 1; padding-left: 1rem; padding-right: 1rem; }', 'class="{open: open}"', function (opts) {
  var self = this;
  self.open = false;
  self.path = opts.path || '';
  self.placeholder = opts.placeholder;

  self.on('updated', function () {
    if (self.open) {
      $(self.q).focus();
    } else {}
  });

  self.clickToggleSearch = function (e) {
    e.preventDefault();
    self.open = !self.open;
    $('body')[self.open ? 'addClass' : 'removeClass']('global-search-active');
  };

  self.submitSearch = function (e) {
    e.preventDefault();
    location.href = util.site_url(self.path, {
      q: self.q.value
    });
  };
});
