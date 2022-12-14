'use strict';

exports.handler = (event, context, callback) => {
  const request = event.Records[0].cf.request;
  let uri = request.uri ? request.uri : '/';
  console.log(uri);

  if (request.querystring) {
    uri += '?' + request.querystring;
  }

  const redirectTo = 'https://${redirect_to}' + uri;

  callback(null, {
    status: '301',
    statusDescription: 'Moved Permanently',
    headers: {
      "strict-transport-security": [{
        key: 'strict-transport-security',
        value: 'max-age=31536000; includeSubDomains'
      }],
      location: [{
        key: 'Location',
        value: redirectTo,
      }]
    }
  });
};