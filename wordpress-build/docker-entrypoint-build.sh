#!/usr/bin/env bash

S3PROXY_CONF='/etc/apache2/sites-available/s3proxy.conf'

uninitialized_build() {
  [ -z "$(cat $WORDPRESS_CONF | grep 's3proxy.conf')" ] && true || false
}

# Replace a placeholder in s3proxy.conf with the actual s3proxy host value.
setS3ProxyHost() {
  echo "setS3ProxyHost..."
  sed -i 's|S3PROXY_HOST_PLACEHOLDER|'$S3PROXY_HOST'|g' $S3PROXY_CONF
}

setForwardedForHost() {
  echo "setForwardedForHost..."
  sed -i 's|FORWARDED_FOR_HOST_PLACEHOLDER|'$FORWARDED_FOR_HOST'|g' $S3PROXY_CONF
}

# Append an include statement for s3proxy.conf as a new line in wordpress.conf directly below a placeholder.
includeS3ProxyConfig() {
  echo "includeS3ProxyConfig..."
  sed -i 's|# PROXY_PLACEHOLDER|Include '${S3PROXY_CONF}'|' $WORDPRESS_CONF
}

if uninitialized_build; then

  setS3ProxyHost

  setForwardedForHost

  includeS3ProxyConfig
fi