#!/usr/bin/env bash

WORDPRESS_CONF='/etc/apache2/sites-enabled/wordpress.conf'
SHIBBOLETH_CONF='/etc/apache2/sites-available/shibboleth.conf'

# Paves over the shibboleth.xml file with a copy of the shibboleth2-template.xml file with the placeholder
# values replaced with the real values that should be available now as environment variables.
editShibbolethXML() {

  echo "editShibbolethXML..."
  local sp_key=${SHIB_SP_KEY:-"sp-key.pem"}
  local sp_cert=${SHIB_SP_CERT:-"sp-cert.pem"}

  insertSpEntityId() { sed "s|SP_ENTITY_ID_PLACEHOLDER|$SP_ENTITY_ID|g" < /dev/stdin; }

  insertIdpEntityId() { sed "s|IDP_ENTITY_ID_PLACEHOLDER|$IDP_ENTITY_ID|g" < /dev/stdin; }

  insertSpKey() { sed "s|SHIB_SP_KEY_PLACEHOLDER|$sp_key|g" < /dev/stdin; }

  insertSpCert() { sed "s|SHIB_SP_CERT_PLACEHOLDER|$sp_cert|g" < /dev/stdin; }

  cat /etc/shibboleth/shibboleth2-template.xml \
    | insertSpEntityId \
    | insertIdpEntityId \
    | insertSpKey \
    | insertSpCert \
  > /etc/shibboleth/shibboleth2.xml
}

# Generate a shibboleth idp metadata file if one does not already exist.
getIdpMetadataFile() {
  echo "getIdpMetadataFile..."
  local xmlfile=/etc/shibboleth/idp-metadata.xml
  if [ ! -f $xmlfile ] ; then
    curl https://shib-test.bu.edu/idp/shibboleth -o $xmlfile
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

# No shib key or cert? Then no shibboleth sp configuration.
requireShibboleth() {
  ([ -n "$SHIB_SP_KEY" ] && [ -n "$SHIB_SP_CERT" ]) && true || false
}

# Append an include statement for shibboleth.conf as a new line in wordpress.conf directly below a placeholder.
includeShibbolethConfig() {
  sed -i 's|# SHIBBOLETH_PLACEHOLDER|Include '${SHIBBOLETH_CONF}'|' $WORDPRESS_CONF
}


if [ "$SHELL" == 'true' ] ; then
  # Keeps the container running, but apache is not started.
  tail -f /dev/null
else

  if uninitialized_baseline ; then

    if requireShibboleth ; then

      editShibbolethXML

      getIdpMetadataFile

      modifyAttributesFile

      includeShibbolethConfig

      service shibd start
    fi

    setVirtualHost
  fi
fi

