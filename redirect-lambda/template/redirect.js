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
      location: [{
        key: 'Location',
        value: redirectTo,
      }]
    }
  });
};