#!/usr/bin/env bash

WORDPRESS_CONF='/etc/apache2/sites-enabled/wordpress.conf'

# Duplicate the wordpress.conf with as a new virtual host (different ServerName directive). 
setVirtualHost() {
  echo "setVirtualHost..."

  sed -i "s|localhost|${SERVER_NAME:-"localhost"}|g" $WORDPRESS_CONF

  sed -i "s|UTC|${TZ:-"UTC"}|g" $WORDPRESS_CONF
}


if [ "$SHELL" == 'true' ] ; then
  # Keeps the container running, but apache is not started.
  tail -f /dev/null
elif [ -n "$(grep 'localhost' $WORDPRESS_CONF)" ] ; then
  # Replace "localhost" in wordpress.conf with name of actual virtual host.
  setVirtualHost
fi

