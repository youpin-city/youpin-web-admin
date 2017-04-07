issue-list
  .level.menu-bar
    .level-left
      .level-item
        span พบทั้งหมด { total } รายการ
    //- div.sorting ▾
    .level-right
      .level-item
        .list-or-map
          span(onclick="{showMapView(false)}", class="{ active: !is_showing_map }")
            i.icon.material-icons.is-medium view_list
            //- | รายการ
          //- span.separator /
          span(onclick="{showMapView(true)}", class="{ active: is_showing_map }")
            i.icon.material-icons.is-medium map
            //- | แผนที่

  div(class="{ hide: is_showing_map, 'list-view': true }")
    ul.issue-list(if='{ pins.length > 0 }')
      li(each='{ p in pins }')
        issue-item(item='{ p }')

    div(if='{ pins.length === 0 }')
      .spacing-large
      .center
        i.icon.material-icons.large location_off
        h5 ไม่พบเรื่องร้องเรียน

      .spacing-large

    .load-more-wrapper.has-text-centered(show='{ hasMore }')
      a.button.load-more(class='{ "is-loading": !loaded }', onclick='{ loadMore }' ) Load More

  div(class="{ hide: !is_showing_map, 'map-view': true }")
    div(id="issue-map")

  script.
    const self = this;

    self.pins = [];
    self.total = 0;
    self.hasMore = true;
    self.loaded = true;
    self.currentQueryOpts = {};
    self.is_showing_map = false;
    self.mapOptions = {};
    self.mapMarkerIcon = L.icon({
      iconUrl: util.site_url('/public/img/marker-m-3d@2x.png'),
      iconSize: [56, 56],
      iconAnchor: [16, 51],
      popupAnchor: [0, -51]
    });

    self.on('mount', () => {
      self.initMap();
    });

    self.load = (opts) => {
      self.currentQueryOpts = opts;
      self.pins = [];
      self.loadMore()
      .then(() => {
        self.removeMapMarkers();
      });
    };

    self.loadMore = () => {
      const opts = _.extend({}, self.currentQueryOpts, {
        $skip: self.pins.length
      });
      self.loaded = false;
      return api.getPins(opts).then( res => {
        self.loaded = true;
        self.pins = self.pins.concat(res.data);
        self.updateHasMoreButton(res);
        self.update();
        return res.data;
      });
    };

    self.updateHasMoreButton = (res) => {
      self.total = res.total || 0;
      self.hasMore = ( res.total - ( res.skip + res.data.length ) ) > 0
    };

    self.showMapView = (show_map) => {
      return () => {
        if (show_map == self.is_showing_map ) { return; }

        self.is_showing_map = show_map
        if (show_map) {
          self.mapMarkers = _.map(self.pins, (p) => {
            let marker = L.marker(p.location.coordinates, {
              icon: self.mapMarkerIcon,
              // interactive: false,
              // keyboard: false,
              // riseOnHover: true
            });
            marker.addTo(self.mapView);
            marker.on('click', () => {
              window.location.hash = '!issue-id:'+ p._id;
            });
            return marker;
          });
        } else {
          self.removeMapMarkers();
        }
        self.update();
        if (show_map){
          // redraw missing tiles when map is initialized with display: none
          // reference https://www.mapbox.com/help/blank-tiles/#your-map-is-hidden
          self.mapView.invalidateSize();
        }
      }
    }

    self.removeMapMarkers = () => {
      _.each( self.mapMarkers, (m) => {
        self.mapView.removeLayer(m)
      });
    }

    self.initMap = () => {
      self.mapView = L.map('issue-map', self.mapOptions);
      self.mapView.setView( app.config.service.map.initial_location, 18);

      // HERE Maps
      // @see https://developer.here.com/rest-apis/documentation/enterprise-map-tile/topics/resource-base-maptile.html
      // https: also suppported.
      const HERE_normalDay = L.tileLayer(app.config.service.leaflet.url, _.extend(app.config.service.leaflet.options, {
        app_id: app.get('service.here.app_id'),
        app_code: app.get('service.here.app_code'),
        scheme: 'ontouchstart' in window ? 'normal.day.mobile' : 'normal.day',
        ppi: 'devicePixelRatio' in window && window.devicePixelRatio >= 2 ? '250' : '72'
      }));
      self.mapView.addLayer(HERE_normalDay);
    };
