#!/usr/bin/env bash

# Check for shib keys.
set +u
if [ -n "$SHIB_SP_KEY" ] && [ -n "$SHIB_SP_CERT" ] ; then
  SHIB_PK_AND_CERT_PROVIDED='true'
fi

WORDPRESS_CONF='/etc/apache2/sites-enabled/wordpress.conf'
SHIBBOLETH_CONF='/etc/apache2/sites-available/shibboleth.conf'

# Paves over the shibboleth.xml file with a copy of the shibboleth2-template.xml file with the placeholder
# values replaced with the real values that should be available now as environment variables.
editShibbolethXML() {

  echo "editShibbolethXML..."

  # Write out the pem file environment variables as files to the same directory as shibboleth2.xml.
  echo -n "$SHIB_SP_KEY" > /etc/shibboleth/sp-key.pem
  echo -n "$SHIB_SP_CERT" > /etc/shibboleth/sp-cert.pem

  insertSpEntityId() { sed "s|SP_ENTITY_ID_PLACEHOLDER|$SP_ENTITY_ID|g" < /dev/stdin; }

  insertIdpEntityId() { sed "s|IDP_ENTITY_ID_PLACEHOLDER|$IDP_ENTITY_ID|g" < /dev/stdin; }

  cat /etc/shibboleth/shibboleth2-template.xml \
    | insertSpEntityId \
    | insertIdpEntityId \
  > /etc/shibboleth/shibboleth2.xml
}

# Put the correct logout url into the shibboleth.conf file
editShibbolethConf() {

  echo "editShibbolethConf..."
  
  sed -i "s|SHIB_IDP_LOGOUT_PLACEHOLDER|$SHIB_IDP_LOGOUT|g" /etc/apache2/sites-available/shibboleth.conf
}

# Generate a shibboleth idp metadata file if one does not already exist.
getIdpMetadataFile() {
  echo "getIdpMetadataFile..."
  local xmlfile=/etc/shibboleth/idp-metadata.xml
  if [ ! -f $xmlfile ] ; then
    curl $IDP_ENTITY_ID -o $xmlfile
  fi
}

# Add buPrincipleNameID (BUID) as an attribute to extract from SAML assertions returned back from the IDP. 
modifyAttributesFile() {
  # Disable this for now:
  return 0

  echo "modifyAttributesFile..."
  local find="<\/Attributes>"
  local insertBefore="    <Attribute name=\"urn:oid:1.3.6.1.4.1.9902.2.1.9\" id=\"buPrincipalNameID\"/>"
  local xmlfile="/etc/shibboleth/attribute-map.xml"
  sed -i "/${find}/i\ ${insertBefore}" ${xmlfile}
}

# Duplicate the wordpress.conf with as a new virtual host (different ServerName directive) with added shibboleth configurations. 
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

MULTISITE_LOG='/var/www/html/multisite.log'
check_multisite() {
  if [ "$MULTISITE" != 'true' ] ; then
    echo "multisite not applicable"
  elif [ -f $MULTISITE_LOG ] ; then
    echo "multisite already installed..."
  else
    echo "installing multisite..."
    wp core multisite-install --title="local root site" \
      --url="http://$SERVER_NAME" \
      --admin_user="admin" \
      --admin_email="user@example.com"
    if [ $? -eq 0 ] ; then
      date > $MULTISITE_LOG
    fi
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

  check_multisite

  check_mu_plugin_loader

  if uninitialized_baseline ; then

    if [ -n "$SHIB_PK_AND_CERT_PROVIDED" ] ; then

      editShibbolethXML

      editShibbolethConf

      getIdpMetadataFile

      modifyAttributesFile

      includeShibbolethConfig

      echo 'shibd start...'
      service shibd start
    fi

    setVirtualHost
  fi
fi