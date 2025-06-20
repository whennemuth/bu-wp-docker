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

# Get the URL for the WP-CLI commands that reflects how wp-config.php has configured the site.
get_wp_cli_url() {
  # Check for local running and possible reverse proxy.
  local protocol="http";
  local port="$DOCKER_SP_PORT"
  if [[ -n "$DOCKER_SP_PORT" && "$DOCKER_SP_PROXY_EXTRAS" == "true" ]] ; then
    # The proxy will always be running over https
    protocol="https";
    [ "$port" -eq "443" ] && port=""
    [ "$port" -eq "80" ] && port=""
    [ -n "$port" ] && port=":$port"
  else
    port=""
  fi    
  echo -n "${protocol}://${SERVER_NAME}${port}"
}

MU_PLUGIN_LOADER='/var/www/html/wp-content/mu-plugins/loader.php'
check_mu_plugin_loader() {
  if [ -f $MU_PLUGIN_LOADER ] ; then
    echo "mu_plugin_loader already generated..."
  else
    local url="$(get_wp_cli_url)"
    echo "generate_mu_plugin_loader for $url ..."
    wp bu-core generate-mu-plugin-loader \
      --url="$url" \
      --path=/var/www/html \
      --require=/var/www/html/wp-content/mu-plugins/bu-core/src/wp-cli.php 2>&1 || true
  fi
}

check_wordpress_install() {

  if ! wp core is-installed 2> /dev/null; then

    # WP is not installed. Let's try installing it.
    local url="$(get_wp_cli_url)"
    echo "installing multisite for $url ..."
    wp core multisite-install --title="local root site" \
      --url="$url" \
      --admin_user="admin" \
      --admin_email="no-use-admin@bu.edu" \
      --skip-email 2>&1 || true

    wp --url="$url" option get siteurl

    else
      # WP is already installed.
      echo "WordPress is already installed. No need to create a new database."
  fi
}

setup_redis() {
  # If there is a REDIS_HOST and REDIS_PORT available in the environment, add them as wp config values.
  if [ -n "$REDIS_HOST" ] && [ -n "$REDIS_PORT" ] ; then
    echo "Redis host detected, setting up Redis..."
    wp config set WP_REDIS_HOST $REDIS_HOST --add --type=constant
    wp config set WP_REDIS_PORT $REDIS_PORT --add --type=constant

    # If there is a REDIS_PASSWORD available in the environment, add it as a wp config value.
    if [ -n "$REDIS_PASSWORD" ] ; then
      wp config set WP_REDIS_PASSWORD $REDIS_PASSWORD --add --type=constant
    fi

    # If the redis-cache plugin is available, create the object-cache.php file and network activate the plugin.
    if wp plugin is-installed redis-cache ; then
      echo "redis-cache plugin detected, setting up object cache..."
      wp plugin activate redis-cache
      wp redis update-dropin
    fi

  fi
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

# EXTRA_CONTENT_INSERTION_POINT
