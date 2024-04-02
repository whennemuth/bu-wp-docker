#!/usr/bin/env bash

WORDPRESS_CONF='/etc/apache2/sites-enabled/wordpress.conf'

# Duplicate the wordpress.conf with as a new virtual host (different ServerName directive). 
setVirtualHost() {
  echo "setVirtualHost..."

  sed -i "s|localhost|${SERVER_NAME:-"localhost"}|g" $WORDPRESS_CONF

  sed -i "s|UTC|${TZ:-"UTC"}|g" $WORDPRESS_CONF
}

# Look for an indication the last step of initialization was run or not.
uninitialized_baseline() {
  [ -n "$(grep 'localhost' $WORDPRESS_CONF)" ] && true || false
}

MU_PLUGIN_LOADER='/var/www/html/wp-content/mu-plugins/loader.php'
check_mu_plugin_loader() {
  if [ -f $MU_PLUGIN_LOADER ] ; then
    echo "mu_plugin_loader already generated..."
  else
    echo "generate_mu_plugin_loader..."
    wp bu-core generate-mu-plugin-loader \
      --path=/var/www/html \
      --require=/var/www/html/wp-content/mu-plugins/bu-core/src/wp-cli.php
  fi
}

check_wordpress_install() {

  if ! wp core is-installed 2> /dev/null; then
    # WP is not installed. Let's try installing it.
    echo "installing multisite..."
    wp core multisite-install --title="local root site" \
      --url="http://$SERVER_NAME" \
      --admin_user="admin" \
      --admin_email="no-use-admin@bu.edu" 2> /dev/null

    else
      # WP is already installed.
      echo "WordPress is already installed. No need to create a new database."
  fi
}

# Append an include statement for shibboleth.conf as a new line in wordpress.conf directly below a placeholder.
includeShibbolethConfig() {
  sed -i 's|# SHIBBOLETH_PLACEHOLDER|Include '${SHIBBOLETH_CONF}'|' $WORDPRESS_CONF
}


if [ "$SHELL" == 'true' ] ; then
  # Keeps the container running, but apache is not started.
  tail -f /dev/null
else

  check_wordpress_install

  check_mu_plugin_loader

  if uninitialized_baseline ; then

    setVirtualHost

  fi
fi
