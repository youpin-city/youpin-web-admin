'use strict';

riot.tag2('dashboard-new-issue-list', '<div class="new-issue-list"> <h1 class="page-title">New issue this week</h1> <ul> <li class="item" each="{data}"><a href="#!issue-id:{_id}"><img riot-src="{photos[0]}"></a><span><a href="#!issue-id:{_id}"><b>{detail} </br></b></a>{created_time} / {status} / {assigned_department.name} / {level}</span></li> </ul> </div>', '', '', function (opts) {
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

riot.tag2('dashboard-recent-activity', '<div class="recent-activity"><b>Recent Activity</b> <ul> <li class="activity" each="{data}"><span><a href="#!issue-id:{pin_id}"><b>{description} </br></b></a>{timestamp}</span></li> </ul> </div>', '', '', function (opts) {
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

riot.tag2('dashboard-table-summary', '<h1 class="page-title">Overview</h1> <ul class="duration-selector"> <li class="{highlight: activeSelector == i}" each="{dur, i in durationSelectors}" onclick="{selectDuration(i)}" title="{dur.start}-today"> <div>{dur.name}</div> </li> </ul> <table class="summary"> <tr> <th class="team">Team</th> <th class="assigned">Assigned</th> <th class="processing">Processing</th> <th class="resolved">Resolved</th> <th class="rejected">Rejected</th> <th class="performance">Performance Index</th> </tr> <tr class="row {hide: shouldHideRow(department._id)}" each="{data}"> <td class="team">{name}</td> <td class="numeric-col">{summary.assigned}</td> <td class="numeric-col">{summary.processing}</td> <td class="numeric-col">{summary.resolved}</td> <td class="numeric-col">{summary.rejected}</td> <td class="performance {positive: performance &gt; 0, negative: performance &lt; 0}">{performance}</td> </tr> </table>', '', '', function (opts) {
  var self = this;
  var ymd = 'YYYY-MM-DD';
  var end_date = moment().add(1, 'day').format(ymd);

  self.activeSelector = 0;

  this.durationSelectors = [{ name: 'week', start: generateStartDate('week', 'day', 1) }, { name: '1 months', start: generateStartDate('month', 'month', 0) }, { name: '2 months', start: generateStartDate('month', 'month', -1) }, { name: '6 months', start: generateStartDate('month', 'month', -5) }];

  this.selectDuration = function (selectorIdx) {
    return function () {
      self.activeSelector = selectorIdx;

      var start_date = self.durationSelectors[selectorIdx].start;

      api.getSummary(start_date, end_date, function (data) {
        var departments = Object.keys(data);

        var attributes = departments.length > 0 ? Object.keys(data[departments[0]]) : [];

        var deptSummaries = _.map(departments, function (dept) {
          return {
            name: dept,
            summary: data[dept],
            performance: computePerformance(attributes, data[dept])
          };
        });

        var all = _.reduce(attributes, function (acc, attr) {
          acc[attr] = 0;
          return acc;
        }, {});

        all = _.reduce(deptSummaries, function (acc, dept) {
          _.each(attributes, function (attr) {
            acc[attr] += dept['summary'][attr];
          });
          return acc;
        }, all);

        var orgSummary = {
          name: 'All',
          summary: all,
          performance: computePerformance(attributes, all)
        };

        self.data = [orgSummary].concat(deptSummaries);

        self.update();
      });
    };
  };

  this.selectDuration(0)();

  function generateStartDate(period, adjPeriod, unit) {
    return moment().isoWeekday(1).startOf(period).add(unit, adjPeriod).format(ymd);
  }

  function computePerformance(attributes, summary) {
    var total = _.reduce(attributes, function (acc, attr) {
      acc += summary[attr];
      return acc;
    }, 0);

    var divider = total - (summary['unverified'] + summary['rejected']);
    if (divider == 0) {
      return 0;
    }

    return summary['resolved'] / divider;
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

riot.tag2('issue-list', '<div class="menu-bar"> <div class="list-or-map"><span class="{active: !isShowingMap}" onclick="{showMapView(false)}">List</span><span class="separator">/</span><span class="{active: isShowingMap}" onclick="{showMapView(true)}">Map</span></div> <div class="clearfix"></div> </div> <div class="{hide: isShowingMap, \'list-view\': true}"> <ul class="issue-list"> <li class="issue clearfix" each="{p in pins}"> <div class="issue-img"> <div class="img responsive-img" riot-style="background-image: url(&quot;{_.get(p.photos, &quot;0&quot;)}&quot;)"></div> </div> <div class="issue-body"> <div class="issue-id"><b>ID</b><span href="#manage-issue-modal" data-id="{p._id}">{p._id}</span></div> <div class="issue-desc">{p.detail}</div> <div class="issue-category"> <div><b>Category</b></div><span class="bubble" each="{cat in p.categories}">{cat}</span> </div> <div class="issue-location"> <div><b>Location</b></div><span class="bubble">Building A</span> </div> <div class="clearfix"></div> <div class="issue-tags"> <div><b>Tag</b></div><span class="bubble" each="{tag in p.tags}">{tag}</span> </div> </div> <div class="issue-info"> <div><b>Status</b></div><span class="big-text">{p.status}</span> <div class="clearfix"></div> <div><b>Dept.</b></div><span class="big-text">{p.assigned_department ? p.assigned_department.name : \'-\'}</span> <div class="clearfix"></div> <div title="assigned to"><i class="icon material-icons">face</i>{p.assigned_user.name}</div> <div title="created at"><i class="icon material-icons">access_time</i>{moment(p.created_time).fromNow()}</div><a class="bt-manage-issue btn" href="#!issue-id:{p._id}">Issue</a> </div> </li> </ul> <div class="load-more-wrapper"><a class="load-more {active: hasMore}" onclick="{loadMore()}">Load More</a></div> </div> <div class="{hide: !isShowingMap, \'map-view\': true}"> <div id="issue-map"></div> </div>', '', '', function (opts) {
  var self = this;

  this.pins = [];
  this.hasMore = true;
  this.isShowingMap = false;
  this.mapOptions = {};
  this.mapMarkerIcon = L.icon({
    iconUrl: util.site_url('/public/img/marker-m-3d.png'),
    iconSize: [36, 54],
    iconAnchor: [16, 51],
    popupAnchor: [0, -51]
  });

  this.load = function (opts) {
    self.currentQueryOpts = opts;

    api.getPins(opts).then(function (res) {
      self.pins = res.data;
      self.updateHasMoreButton(res);
      self.isShowingMap = false;

      self.removeMapMarkers();

      self.update();
    });
  };

  this.loadMore = function () {
    return function () {
      var opts = _.extend({}, self.currentQueryOpts, { '$skip': self.pins.length });
      api.getPins(self.selectedStatus, opts).then(function (res) {
        self.pins = self.pins.concat(res.data);
        self.updateHasMoreButton(res);
        self.update();
      });
    };
  };

  this.updateHasMoreButton = function (res) {
    self.hasMore = res.total - (res.skip + res.data.length) > 0;
  };

  this.showMapView = function (showMap) {
    return function () {
      if (showMap == self.isShowingMap) {
        return;
      }

      self.isShowingMap = showMap;
      if (showMap) {

        self.mapMarkers = _.map(self.pins, function (p) {
          var marker = L.marker(p.location.coordinates, {
            icon: self.mapMarkerIcon

          }).addTo(self.mapView);
          marker.on('click', function () {
            window.location.hash = '!issue-id:' + p._id;
          });
          return marker;
        });
      } else {
        self.removeMapMarkers();
      }
      self.update();
      if (showMap) {

        self.mapView.invalidateSize();
      }
    };
  };

  this.on('mount', function () {
    self.mapView = L.map('issue-map', self.mapOptions);
    self.mapView.setView(app.config.service.map.initial_location, 18);

    var HERE_normalDay = L.tileLayer('https://{s}.{base}.maps.cit.api.here.com/maptile/2.1/{type}/{mapID}/{scheme}/{z}/{x}/{y}/{size}/{format}?app_id={app_id}&app_code={app_code}&lg={language}&style={style}&ppi={ppi}', {
      attribution: 'Map &copy; 1987-2014 <a href="https://developer.here.com">HERE</a>',
      subdomains: '1234',
      mapID: 'newest',
      app_id: app.get('service.here.app_id'),
      app_code: app.get('service.here.app_code'),
      base: 'base',
      maxZoom: 20,
      type: 'maptile',
      scheme: 'ontouchstart' in window ? 'normal.day.mobile' : 'normal.day',
      language: 'tha',
      style: 'default',
      format: 'png8',
      size: '256',
      ppi: 'devicePixelRatio' in window && window.devicePixelRatio >= 2 ? '250' : '72'
    });
    self.mapView.addLayer(HERE_normalDay);
  });

  this.removeMapMarkers = function () {
    _.each(self.mapMarkers, function (m) {
      self.mapView.removeLayer(m);
    });
  };
});

riot.tag2('issue-page', '<h1 class="page-title">Issue <div class="bt-new-issue"><a class="btn" href="#manage-issue-modal">Create New Issue</a></div> </h1> <ul class="status-selector"> <li class="{active: name == selectedStatus}" each="{statuses}" onclick="{parent.select(name)}">{name}({totalIssues})</li> </ul> <issue-list></issue-list>', '', '', function (opts) {
  var _this = this;

  var self = this;

  this.statusesForRole = [];

  var queryOpts = {};

  if (user.role == 'super_admin' || user.role == 'organization_admin') {
    this.statusesForRole = ['unverified', 'verified', 'assigned', 'processing', 'resolved', 'rejected'];
  } else {
    this.statusesForRole = ['assigned', 'processing', 'resolved'];
    queryOpts['assigned_department'] = user.department;
  }

  this.statuses = [];

  Promise.map(this.statusesForRole, function (status) {

    var opts = _.extend({}, queryOpts, {
      '$limit': 1,
      status: status
    });

    return api.getPins(opts).then(function (res) {
      return {
        name: status,
        totalIssues: res.total
      };
    });
  }).then(function (data) {
    self.statuses = data;
    self.update();

    _this.select(self.statuses[0].name)();
  });

  this.selectedStatus = this.statusesForRole[0];

  this.select = function (status) {
    return function () {
      self.selectedStatus = status;

      var query = _.extend({
        status: status
      }, queryOpts);

      self.tags['issue-list'].load(query);
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
  self.path = util.site_url('/search') + '?q=<QUERY>';
  self.placeholder = opts.placeholder;

  var prevQuery = queryString.parse(location.search).q;
  if (prevQuery) {
    self.open = true;
    $(self.q).val(prevQuery);
    $('body').addClass('global-search-active');
  }

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
    if (self.q.value == '') {
      return;
    }
    e.preventDefault();

    var url = self.path.replace(/<QUERY>/, self.q.value);
    location.href = url;
  };
});

riot.tag2('search-page', '<div class="{hidden: !isNoIssue}"> <h1 class="page-title">No result for "{query}"</h1> </div> <div class="{hidden: isNoIssue}"> <h1 class="page-title">Search result for "{query}"</h1> <issue-list></issue-list> </div>', '', '', function (opts) {
  var self = this;

  self.isNoResult = false;

  self.query = queryString.parse(location.search).q;

  self.issueList = self.tags['issue-list'];

  self.on('mount', function () {
    self.tags['issue-list'].load({
      'detail[$regex]': '.*' + self.query + '.*',
      '$sort': '-created_time',
      'assigned_department': user.department
    });
  });

  self.issueList.on('update', function () {
    self.isNoIssue = self.issueList.pins.length == 0;
    self.update();
  });
});

riot.tag2('setting-department', '<h1 class="page-title">Department Settings</h1> <div class="row"> <div class="col s12 right-align"><a class="btn" onclick="{createDepartment}">Create Department</a></div> </div> <table> <thead> <tr> <th>Department</th> <th style="width: 120px"></th> </tr> </thead> <tbody> <tr class="department" each="{dept in departments}"> <td><b>{dept.name}</b></td> <td><a class="btn btn-small btn-block" onclick="{editDepartment(dept._id)}">Edit</a></td> </tr> </tbody> </table> <div class="modal" id="edit-department-form"> <div class="modal-header"> <h3>Edit Department</h3> </div> <div class="divider"></div> <div class="modal-content">something</div> </div> <div class="modal" id="create-department-form"> <div class="modal-header"> <h3>Create Department</h3> </div> <div class="modal-content"> <h5>Department name</h5> <div class="input-field"> <input type="text" name="name"> </div> </div> <div class="row"> <div class="col s12 right-align"><a class="btn-flat" onclick="{closeCreateModal}">Cancel</a>&nbsp;<a class="btn" onclick="{confirmCreate}">Create</a></div> </div> </div>', '', '', function (opts) {
  var self = this;
  var $editModal = void 0,
      $createModal = void 0;

  $(document).ready(function () {
    $editModal = $('#edit-department-form').modal();
    $createModal = $('#create-department-form').modal();
  });

  this.departments = [];

  self.loadData = function () {
    api.getDepartments().then(function (res) {
      self.departments = res.data;
      self.update();
    });
  };

  self.loadData();

  self.editDepartment = function (deptId) {
    return function () {
      var $modal = $editModal;

      console.log('------');

      $modal.trigger('openModal');
    };
  };

  self.createDepartment = function () {
    var $modal = $createModal;

    var $input = $modal.find('input[name="name"]');
    $input.val('');

    console.log('creating new department');

    $modal.trigger('openModal');
  };

  self.closeCreateModal = function () {
    var $modal = $createModal;
    $modal.trigger('closeModal');
  };

  self.confirmCreate = function () {
    var $modal = $createModal;
    var $input = $modal.find('input[name="name"]');

    console.log('creating ' + $input.val());

    api.createDepartments(user.organization, $input.val()).then(function (res) {
      if (res.status != "201") {
        alert("something wrong : check console");
        console.log(res);
        return;
      }

      self.closeCreateModal();
      self.loadData();
    });
  };
});

riot.tag2('setting-user', '<h1 class="page-title">User Settings</h1> <div class="row"> <div class="col s12 right-align"><a class="btn" onclick="{createUser}">Create User</a></div> </div> <table> <thead> <th>Name</th> <th>Email</th> <th>Department</th> <th>Role</th> <th style="min-width: 100px"></th> </thead> <tr class="user" each="{user in users}"> <td>{user.name}</td> <td>{user.email}</td> <td>{user.department.name}</td> <td>{user.role}</td> <td><a class="btn btn-small btn-block" onclick="{changeRole(user)}">Edit</a></td> </tr> </table> <div class="modal" id="change-role-form"> <div class="modal-header"> <h3>Change role of {editingUser.name}</h3> </div> <div class="divider"></div> <div class="modal-content"> <h5>Role</h5> <div class="input-field col s12"> <select name="role"> <option each="{role in availableRoles}" value="{role.id}" __selected="{role.id === editingUser.role}">{role.name}</option> </select> </div> <div class="department-selector-wrapper"> <h5>Department</h5> <div class="input-field col s12"> <select name="department"> <option each="{dept in departments}" value="{dept._id}" __selected="{dept._id === editingUser.department._id}">{dept.name}</option> </select> </div> </div> <div class="padding"></div> </div> <div class="row"> <div class="col s12 right-align"><a class="btn-flat" onclick="{closeChangeRoleModal}">Cancel</a>&nbsp;<a class="btn" onclick="{confirmChangeRole}">Save</a></div> </div> </div> <div class="modal" id="create-user-form"> <div class="modal-header"> <h3>Create User</h3> </div> <div class="modal-content"> <h5>Name</h5> <div class="input-field"> <input type="text" name="name"> </div> <h5>Email</h5> <div class="input-field"> <input type="text" name="email"> </div> <h5>Password</h5> <div class="input-field"> <input type="password" name="password"> </div> <h5>Confirm Password</h5> <div class="input-field"> <input type="password" name="confirm-password"> </div> </div> <div class="row"> <div class="col s12 right-align"><a class="btn-flat" onclick="{closeCreateModal}">Cancel</a>&nbsp;<a class="btn" onclick="{confirmCreate}">Create</a></div> </div> </div>', '', '', function (opts) {
  var self = this;
  var $changeRoleModal = void 0,
      $createModal = void 0,
      $roleSelector = void 0,
      $departmentSelector = void 0;

  self.availableRoles = opts.availableRoles || [];
  $(document).ready(function () {
    $changeRoleModal = $('#change-role-form').modal();
    $createModal = $('#create-user-form').modal();

    $roleSelector = $changeRoleModal.find('select[name="role"]');
    $departmentSelector = $changeRoleModal.find('select[name="department"]');

    $roleSelector.on('change', function () {
      var selectedRole = $roleSelector.val();
    });
  });

  this.users = [];

  self.loadData = function () {
    api.getUsers().then(function (res) {
      self.users = res.data;
      self.update();
    });
  };

  api.getDepartments().then(function (res) {
    self.departments = res.data;
    self.loadData();
  });

  self.changeRole = function (userObj) {
    return function () {
      self.editingUser = userObj;
      self.update();

      $roleSelector.material_select();
      $departmentSelector.material_select();

      var $modal = $changeRoleModal;

      $modal.trigger('openModal');
    };
  };

  self.confirmChangeRole = function () {
    var patch = {
      role: $roleSelector.val(),
      department: [$departmentSelector.val()]
    };

    if (patch.role == "super_admin") {
      delete patch['department'];
    }

    api.updateUser(self.editingUser._id, patch).then(function (res) {
      if (res.status != "200") {
        alert("something wrong : check console");
        console.log(res);
        return;
      }
      self.closeChangeRoleModal();
      self.loadData();
    });
  };

  self.closeChangeRoleModal = function () {
    var $modal = $changeRoleModal;
    $modal.trigger('closeModal');
  };

  self.createUser = function () {
    var $modal = $createModal;

    var $input = $modal.find('input[name="name"]');
    $input.val('');

    $modal.trigger('openModal');
  };

  self.closeCreateModal = function () {
    var $modal = $createModal;
    $modal.trigger('closeModal');
  };

  self.confirmCreate = function () {
    var $modal = $createModal;

    var fields = ['name', 'email', 'password', 'confirm-password'];
    var userObj = _.reduce(fields, function (acc, f) {
      acc[f] = $modal.find('input[name="' + f + '"]').val();
      return acc;
    }, {});

    if (userObj['confirm-password'] != userObj['password']) {
      alert('Password is not matched!');
      return;
    }

    delete userObj['confirm-password'];

    api.createUser(userObj).then(function (res) {
      if (res.status != "201") {
        alert("something wrong : check console");
        console.log(res);
        return;
      }

      self.closeCreateModal();
      self.loadData();
    });
  };
});
