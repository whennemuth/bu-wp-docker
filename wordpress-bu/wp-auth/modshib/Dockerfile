ARG DOCKER_REGISTRY
ARG DOCKER_WORDPRESS_REPO
ARG DOCKER_WORDPRESS_TAG

FROM ${DOCKER_REGISTRY}/${DOCKER_WORDPRESS_REPO}:${DOCKER_WORDPRESS_TAG}

# Configure shibboleth in .htaccess
RUN echo "" >> /var/www/html/.htaccess && \
    echo "AuthType shibboleth" >> /var/www/html/.htaccess && \
    echo "Require shibboleth" >> /var/www/html/.htaccess

# Modify custom error page for unathorized access in 401-unathorized.php
RUN find='^\$login_url\s*=\s*[^\s].*$' && \
    replace='$login_url = urldecode($_SERVER["HTTP_SHIB_HANDLER"]);' && \
    sed -i "s|$find|$replace|" /var/www/html/_s3proxy-custom-errors/401-unathorized.php;

# Install mod-shib components
RUN \
  apt-get -y install libapache2-mod-shib && \
  apache2ctl -M | grep mod_shib && \
  a2enmod shib

# Add other shibboleth related configuration files
COPY --chmod=766 shibboleth2-template.xml /etc/shibboleth/
COPY --chmod=766 attribute-map.xml /etc/shibboleth/
COPY --chmod=766 shibboleth.conf /etc/apache2/sites-available/
COPY --chmod=766 shib.conf /etc/apache2/conf-available/

# "Pave over" the existing wordpress.conf file
COPY --chmod=766 wordpress.conf /etc/apache2/sites-enabled/

# Add the custom docker entrypoint scripting
COPY --chmod=777 docker-entrypoint-modshib.sh /usr/local/bin/

# Extend the entrypoint script by inserting a source command for the content of 
# docker-entrypoint-modshib.sh directly below the line in the original script that reads "EXTRA_CONTENT_INSERTION_POINT"
RUN \
  sed -i "/EXTRA_CONTENT_INSERTION_POINT "$@"/i\source docker-entrypoint-modshib.sh \$@" /usr/local/bin/docker-entrypoint.sh
