/* global util _ app user api Materialize*/

const modalId = '#map-issue-modal';
const dataKey = ' issue-id';
const mapViewId = 'map-issue-box';
const mapOptions = {};

let mapView;
let mapMarker;
let mapCenter;
let mapMarkerIcon;

const issueMapRouter = module.exports = {
  setup: () => {
    $(modalId).modal({
      ready: issueMapRouter.modalOpen,
      complete: issueMapRouter.modalClose
    });

    $(modalId).on('click', '.modal-close', () => {
      $(modalId).modal('close');
    });

    mapMarkerIcon = L.icon({
      iconUrl: util.site_url('/public/img/marker-m-3d@2x.png'),
      iconSize: [56, 56],
      iconAnchor: [16, 51],
      popupAnchor: [0, -51]
    });
    mapView = L.map(mapViewId, mapOptions);
    mapView.setView( app.config.service.map.initial_location, 18);

    // HERE Maps
    // @see https://developer.here.com/rest-apis/documentation/enterprise-map-tile/topics/resource-base-maptile.html
    // https: also suppported.
    const HERE_normalDay = L.tileLayer(app.config.service.leaflet.url, _.extend(app.config.service.leaflet.options, {
      app_id: app.get('service.here.app_id'),
      app_code: app.get('service.here.app_code'),
      scheme: 'ontouchstart' in window ? 'normal.day.mobile' : 'normal.day',
      ppi: 'devicePixelRatio' in window && window.devicePixelRatio >= 2 ? '250' : '72'
    }));
    mapView.addLayer(HERE_normalDay);
  },

  process: (issueId) => {
    $(modalId).data(dataKey, issueId);
    $(modalId).trigger('openModal');
  },

  modalClose: (modal, trigger) => {
    const $modal = $(modalId);
    const issueId = $modal.data(dataKey);
    location.hash = '';
    issueMapRouter.removeMarker(mapMarker);
  },

  modalOpen: (modal, trigger) => {
    const $modal = $(modalId);
    const issueId = $modal.data(dataKey);
    api.getPin(issueId)
    .then(data => {
      mapCenter = _.get(data, 'location.coordinates', null);
      if (mapCenter) {
        issueMapRouter.createMarker(mapCenter);
      }
    });
  },

  createMarker: (latlng) => {
    setTimeout(function() {
      mapView.panTo(latlng);
      mapMarker = L.marker(latlng, {
        icon: mapMarkerIcon,
        // interactive: false,
        // keyboard: false,
        // riseOnHover: true
      })
      .addTo(mapView);
    }, 1000);
  },

  removeMarker: (marker) => {
    if (marker) {
      mapView.removeLayer(marker);
    }
  }
};
