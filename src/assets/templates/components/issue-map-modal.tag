issue-map-modal
  .content
    #issue-map-modal.modal-content
      //- .modal-header
      //-   .title Map
      .map-section
        header
          .is-pulled-right
            button.delete.close-btn(onclick='{ closeModal }')
          .field.is-inline.is-pulled-right(show='{ external_url }')
            a(href='{ external_url }', target='_blank') ดูบน Google Maps
          .subtitle ตำแหน่งสถานที่
        #issue-map-box.map-view


  script.
    const self = this;
    self._target = opts.target;
    self._content = '.content';
    self.classes = _.compact((opts.class || '').split(' '));
    self.position = 'bottom center';
    self.external_url = '';

    self.mapViewId = 'issue-map-box';
    self.mapOptions = {};
    self.mapCenter = null;
    self.mapAddress = '';

    self.mapView = null;
    self.mapMarker = null;
    self.mapMarkerIcon = null;

    self.on('before-mount', () => {
      self.id = self.opts.dataId;
      if (opts.position) self.position = opts.position;
    });

    self.on('mount', () => {
      self.$target = $(self._target);
      self.target = self.$target.get(0);

      self.$content = $(self.root).find(self._content);
      self.content = self.$content.get(0);

      if (self.target && self.content) {
        self.drop = new Drop({
          target: self.target,
          content: self.content,
          position: self.position,
          classes: ['issue-map-modal'].concat(self.classes).join(' '),
          constrainToWindow: true,
          // constrainToScrollParent: true,
          openOn: 'click',
          remove: 'true',
          tetherOptions: {}
        });
        self.drop.on('open', self.modalOpen);
        self.drop.on('close', self.modalClose);
      }

      if (self.opts.address) self.mapAddress = self.opts.address;
      if (self.opts.location) {
        if (typeof self.opts.location === 'string') {
          self.mapCenter = _.map(self.opts.location.split(','), num => Number(num));
          //- self.setLocation(_.map(self.opts.location.split(','), num => Number(num)));
        } else if (_.isArray(self.opts.location)) {
          self.mapCenter = self.opts.location;
          //- self.setLocation(self.opts.location);
        }
      }
    });

    self.closeModal = () => {
      if (self.drop) {
        self.drop.close();
      }
    }

    self.modalOpen = () => {
      self.createMap();
      self.createMarker(self.mapCenter);
      //- self.loadMap();
    };

    self.modalClose = () => {
      if (self.mapMarker) {
        self.removeMarker(self.mapMarker);
      }
    };

    self.setLocation = (latlong) => {
      if (latlong) {
        self.mapCenter = latlong;
        self.external_url = `http://maps.google.com/?q=${self.mapCenter[0]},${self.mapCenter[1]}`;
        if (self.marker) self.removeMarker(self.marker);
        self.createMarker(self.mapCenter);
      }
    }

    self.createMap = () => {
      if (self.mapView) return;
      self.mapMarkerIcon = L.icon({
        iconUrl: util.site_url('/public/img/marker-m-3d@2x.png'),
        iconSize: [56, 56],
        iconAnchor: [16, 51],
        popupAnchor: [0, -51]
      });
      self.mapView = L.map(self.mapViewId, self.mapOptions);
      self.mapView.setView( app.config.service.map.initial_location, 17);

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
    }

    //- self.loadMap = () => {
    //-   if (!self.mapCenter) return;
    //-   api.getPin(self.id)
    //-   .then(data => {
    //-     self.setLocation(_.get(data, 'location.coordinates', null));
    //-     //- self.mapCenter = _.get(data, 'location.coordinates', null);
    //-     //- if (self.mapCenter) {
    //-     //-   self.createMarker(self.mapCenter);
    //-     //- }
    //-   });
    //- }

    self.createMarker = (latlng) => {
      //- setTimeout(function() {
        self.mapView.panTo(latlng);
        self.mapMarker = L.marker(latlng, {
          icon: self.mapMarkerIcon,
          // interactive: false,
          // keyboard: false,
          // riseOnHover: true
        })
        .addTo(self.mapView);
      //- }, 100);
    };

    self.removeMarker = (marker) => {
      if (marker) {
        self.mapView.removeLayer(marker);
      }
    };
