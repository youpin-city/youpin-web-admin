issue-list
  div.menu-bar
    //- div.sorting ▾
    div.list-or-map
        span(onclick="{showMapView(false)}", class="{ active: !isShowingMap }") List
        span.separator /
        span(onclick="{showMapView(true)}", class="{ active: isShowingMap }") Map
    div.clearfix

  div(class="{ hide: isShowingMap, 'list-view': true }")
    ul.issue-list(if='{ pins.length > 0 }')
      li.issue.clearfix(each="{ p in pins }")
        .issue-img
          div.img.responsive-img(style='background-image: url("{ _.get(p.photos, "0") }");')
          //- img.issue-img(src="http://lorempixel.com/150/150/city/")

          div.issue-id
            label ID
            span(href='#manage-issue-modal' data-id='{ p._id }') { p._id.slice(-10) }

        div.issue-body
          div.issue-desc
            //- b Description
            div { p.detail }

          footer
            div.meta.issue-location
              i.icon.material-icons.tiny location_on
              span
                a.bubble(if='{ p.location && p.location.coordinates }', href='#')
                  | See map
                span.bubble(if='{ p.location_name }') { p.location_name }
            div.meta.issue-category(if='{ p.categories && p.categories.length > 0 }')
              i.icon.material-icons.tiny turned_in_not
              span
                span.bubble(each="{ cat in p.categories }") { cat }
            div.meta.issue-tags(if='{ p.tags && p.tags.length > 0 }')
              i.icon.material-icons.tiny label
              span
                span.bubble(each="{ tag in p.tags }") { tag }
        div.issue-info
          div
            label Status
            span.big-text { p.status }

          div
            label Dept.
            span.big-text { p.assigned_department ? p.assigned_department.name : '-' }

          div.meta(if='{p.owner}', title="assigned to")
            i.icon.material-icons.tiny face
            | { p.owner.name }

          div.meta(title="created at")
            i.icon.material-icons.tiny access_time
            | { moment(p.created_time).fromNow() }
            //- | [date& time]
          div
            a.bt-manage-issue.btn.btn-block(href='#!issue-id:{ p._id }') Issue

    div(if='{ pins.length === 0 }')
      .spacing-large
      .center
        i.icon.material-icons.large location_off
        h5 No issue

      .spacing-large

    div.load-more-wrapper
      a.load-more(class="{active: hasMore}", onclick="{loadMore()}" ) Load More

  div(class="{ hide: !isShowingMap, 'map-view': true }")
    div(id="issue-map")

  script.
    let self = this;

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


    this.load = (opts) => {
        self.currentQueryOpts = opts;

        api.getPins(opts).then( res => {
          self.pins = res.data;
          self.updateHasMoreButton(res);
          self.isShowingMap = false;

          self.removeMapMarkers();

          self.update();
        });
    }

    this.loadMore = () => {
      return () => {
        let opts = _.extend( {}, self.currentQueryOpts, { '$skip': self.pins.length });
        api.getPins( self.selectedStatus, opts ).then( res => {
          self.pins = self.pins.concat(res.data)
          self.updateHasMoreButton(res);
          self.update();
        });
      };
    }

    this.updateHasMoreButton = (res) => {
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
        language: 'tha',// 'eng',
        style: 'default',
        format: 'png8',
        size: '256',
        ppi: 'devicePixelRatio' in window && window.devicePixelRatio >= 2 ? '250' : '72'
      });
      self.mapView.addLayer(HERE_normalDay);
    });

    this.removeMapMarkers = () => {
      _.each( self.mapMarkers, (m) => {
        self.mapView.removeLayer(m)
      });
    }
