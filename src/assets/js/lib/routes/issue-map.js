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

    // OpenStreetMap Maps
    // https: also suppported.
    const OpenStreetMap_Mapnik = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    });
    mapView.addLayer(OpenStreetMap_Mapnik);
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
