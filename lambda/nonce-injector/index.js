'use strict';
import { randomBytes } from "crypto";
import { GetObjectCommand, S3Client } from "@aws-sdk/client-s3";

/** @type{S3Client} */
let s3Client;

/** @type{{contents: string, etag: string, date: Date} | null} */
let CACHE = null;

/**
* Fetches and caches index.html
* @param {string} bucket
* @param {string} region
* @returns {string}
*/
async function getIndex(bucket, region) {
  /** @type{string} */
  let html;
  let pullS3 = true;
  let refresh = false;
  const etag = CACHE && CACHE.etag || null;
  try {
    if (CACHE) {
      if (CACHE.date < new Date()) {
        // A refresh is needed
        refresh = true;
      } else {
        pullS3 = false;
      }
    }
    if (!pullS3 && CACHE) {
      html = CACHE.contents;
    } else {
      if (!s3Client) {
        s3Client = new S3Client({ region: region });
      }
      const s3Object = await s3Client.send(
        new GetObjectCommand({
          Bucket: bucket,
          Key: 'index.html',
          IfNoneMatch: etag || undefined,
        })
      );
      html = await s3Object?.Body?.transformToString("UTF-8");
      // Don't check S3 for 1 minute at a time
      CACHE = {
        contents: html,
        etag: s3Object?.ETag,
        date: new Date(new Date().getTime() + 60_000)
      };
    }
  } catch (ex) {
    // S3ServiceException
    if (ex.$response?.statusCode === 304) {
      html = CACHE.contents;
      if (refresh && CACHE) {
        // Refresh the cache date
        CACHE.date = new Date(new Date().getTime() + 60_000);
      }
    } else {
      console.error("Could not fetch resource", ex);
      throw ex;
    }
  }
  return html;
}

/**
* Rewrites Content Security Policy with nonce
* @param {string | null} contentSecurityPolicy
* @param {string} nonce
* @returns {string}
*/
function rewriteCsp(contentSecurityPolicy, nonce) {
  if (!contentSecurityPolicy) {
    // Have a sane default if misconfigured
    contentSecurityPolicy =
      "default-src 'none'; img-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'";
  }
  try {
    // Disassemble the content security policy set up in CDK
    const policies = contentSecurityPolicy.split(';');
    for (let i = 0; i < policies.length; i++) {
      const policy = policies[i].trim();
      let key, value;
      if (policy.includes(' ')) {
        [key, value] = policies[i].trim().split(/ (.*)/s);
      } else {
        key = policy;
        value = '';
      }
      if (key == 'script-src') {
        // Remove 'self'
        value = value.replaceAll("'self'", '').trim();
        // 'unsafe-inline' is ignored if nonces are supported.
        value = `'strict-dynamic' 'nonce-${nonce}' ${value} 'unsafe-inline'`;
        policies[i] = `${key} ${value.trim()}`;
      } else if (key == 'style-src') {
        value = `'nonce-${nonce}' ${value}`
        policies[i] = `${key} ${value.trim()}`;
      }
    }
    contentSecurityPolicy = policies.join('; ');
    // Add back in the reassembled policy
  } catch (ex) {
    console.error("Could not rewrite content security policy", ex);
  }
  return contentSecurityPolicy;
}

export const handler = async (event) => {
  //Get contents of response
  const request = event.Records[0].cf.request;
  console.log('Event received:', JSON.stringify(event, null, 2));

  let rewrite = false;
  /** @type {string} */
  const path = request.uri;
  if (path.includes('.')) {
    const extension = path.split('.').pop()
    if (extension == 'html') {
      rewrite = true;
    }
  } else {
    rewrite = true;
  }

  let [bucket,,region] =
    request.origin.s3.domainName.split('.', 3);

  if (rewrite && bucket) {
    const nonce = randomBytes(16)
      .toString("base64")
      .replaceAll('=', '');
    let html = await getIndex(bucket, region);

    // We aren't giving the same response so we need to
    // rebuild the headers
    /** @type{{[header:string]: {key: string, value: string}[]}} */
    const newHeaders = {};

    /** @type{string} */
    let contentSecurityPolicy = null;
    if (request.origin.s3.customHeaders['x-csp']) {
      // Load injected CSP with additional information
      contentSecurityPolicy =
        request.origin.s3.customHeaders['x-csp'][0].value;
    }

    contentSecurityPolicy =
      rewriteCsp(contentSecurityPolicy, nonce);

    if (html) {
      html = html
        .replaceAll('<script', `<script nonce="${nonce}"`)
        .replaceAll('<style', `<style nonce="${nonce}"`)
        // This is specific to an angular app with a root element
        // of "app-root"
        .replaceAll('<app-root', `<app-root ngCspNonce="${nonce}"`);

      newHeaders['content-type'] =
        [{key: 'Content-Type', value: 'text/html'}];
      newHeaders['content-encoding'] =
        [{key: 'Content-Encoding', value: 'UTF-8'}];
      // Send private cache only
      newHeaders['cache-control'] = [{
        key: 'Cache-Control',
        value: 'must-understand, private, max-age=600'
      }];
      newHeaders['content-security-policy'] = [{
        key: 'Content-Security-Policy',
        value: contentSecurityPolicy
      }];
      // Set the response body with the nonce-ified html
      const response = {
        status: 200,
        statusDescription: 'OK',
        body: html,
        headers: newHeaders
      }
      return response;
    }
  }
  return request;
};