const https = require('https');
const keys = [
  { key: 'AIzaSyC7qwg236rAroYuvXNhOzMRFCnJKZA7Biw', label: 'google-services.json key' },
  { key: 'AIzaSyDj1zXQ38uxfAAOjGePDC0hz9rQzhFFke4', label: 'local.properties key' },
  { key: 'AIzaSyASe7ZE2Vvy5oDTzWZfdaqedOKX9tct49c', label: 'GOOGLE_MAPS_SERVER_KEY' },
];
const testKey = (k) => new Promise((resolve) => {
  const url = 'https://maps.googleapis.com/maps/api/geocode/json?address=New+York&key=' + k.key;
  https.get(url, (res) => {
    let data = '';
    res.on('data', d => data += d);
    res.on('end', () => {
      const j = JSON.parse(data);
      console.log(k.label + ': ' + j.status + ' ' + (j.error_message || (j.results && j.results[0] ? j.results[0].formatted_address : '')));
      resolve();
    });
  }).on('error', e => { console.log(k.label + ' ERROR: ' + e.message); resolve(); });
});
Promise.all(keys.map(testKey));
