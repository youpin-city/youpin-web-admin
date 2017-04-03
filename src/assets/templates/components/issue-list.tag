issue-list
  .lavel.menu-bar
    .level-left
      .level-item
        span พบทั้งหมด { total } รายการ
    //- div.sorting ▾
    .level-right
      .level-item
        .list-or-map
          span(onclick="{showMapView(false)}", class="{ active: !isShowingMap }") List
          span.separator /
          span(onclick="{showMapView(true)}", class="{ active: isShowingMap }") Map
    div.clearfix

  div(class="{ hide: isShowingMap, 'list-view': true }")
    ul.issue-list(if='{ pins.length > 0 }')
      li(each='{ p in pins }')
        issue-item(item='{ p }')

    div(if='{ pins.length === 0 }')
      .spacing-large
      .center
        i.icon.material-icons.large location_off
        h5 No issue

      .spacing-large

    .load-more-wrapper.has-text-centered(show='{ hasMore }')
      a.button.load-more(class='{ "is-loading": !loaded }', onclick='{ loadMore }' ) Load More

  div(class="{ hide: !isShowingMap, 'map-view': true }")
    div(id="issue-map")

  script.
    const self = this;

    self.pins = [];
    self.total = 0;
    self.hasMore = true;
    self.loaded = true;
    self.isShowingMap = false;
    self.mapOptions = {};
    self.mapMarkerIcon = L.icon({
      iconUrl: util.site_url('/public/img/marker-m-3d@2x.png'),
      iconSize: [56, 56],
      iconAnchor: [16, 51],
      popupAnchor: [0, -51]
    });

    self.load = (opts) => {
      self.currentQueryOpts = opts;
      self.loaded = false;
      api.getPins(opts).then( res => {
        self.loaded = true;
        self.pins = _.map(res.data, pin => {
          pin.assigned_user_names = _.get(pin, 'assigned_users.length', 0) > 0
            ? _.map(pin.assigned_users, u => u.name).join(', ')
            : '';
          return pin;
        });
        self.updateHasMoreButton(res);
        self.isShowingMap = false;

        self.removeMapMarkers();

        self.update();
      });
    }

    this.loadMore = () => {
      let opts = _.extend( {}, self.currentQueryOpts, { '$skip': self.pins.length });
      self.loaded = false;
      api.getPins( self.selectedStatus, opts ).then( res => {
        self.loaded = true;
        self.pins = self.pins.concat(res.data)
        self.updateHasMoreButton(res);
        self.update();
      });
    }

    this.updateHasMoreButton = (res) => {
      self.total = res.total || 0;
      self.hasMore = ( res.total - ( res.skip + res.data.length ) ) > 0
    }

    this.showMapView = (showMap) => {
      return () => {
        if(showMap == self.isShowingMap ) { return; }

        self.isShowingMap = showMap
        if(showMap) {

          self.mapMarkers = _.map(self.pins, (p) => {
            let marker = L.marker( p.location.coordinates, {
              icon: self.mapMarkerIcon,
              // interactive: false,
              // keyboard: false,
              // riseOnHover: true
            } ).addTo(self.mapView);
            marker.on('click', () => {
                window.location.hash = '!issue-id:'+ p._id;
            });
            return marker;
          });

        } else {
          self.removeMapMarkers();
        }
        self.update();
        if(showMap){
          // redraw missing tiles when map is initialized with display: none
          // reference https://www.mapbox.com/help/blank-tiles/#your-map-is-hidden
          self.mapView.invalidateSize();
        }
      }
    }

    this.on('mount', () => {
      self.mapView = L.map('issue-map', self.mapOptions);
      self.mapView.setView( app.config.service.map.initial_location, 18);

      // HERE Maps
      // @see https://developer.here.com/rest-apis/documentation/enterprise-map-tile/topics/resource-base-maptile.html
      // https: also suppported.
      var HERE_normalDay = L.tileLayer(app.config.service.leaflet.url, _.extend(app.config.service.leaflet.options, {
        app_id: app.get('service.here.app_id'),
        app_code: app.get('service.here.app_code'),
        scheme: 'ontouchstart' in window ? 'normal.day.mobile' : 'normal.day',
        ppi: 'devicePixelRatio' in window && window.devicePixelRatio >= 2 ? '250' : '72'
      }));
      self.mapView.addLayer(HERE_normalDay);
    });

    this.removeMapMarkers = () => {
      _.each( self.mapMarkers, (m) => {
        self.mapView.removeLayer(m)
      });
    }
