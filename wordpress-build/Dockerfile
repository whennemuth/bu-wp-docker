FROM bu-wordpress-baseline AS baseline

# -----------------------------------------------------------
#                      STAGE 1
# -----------------------------------------------------------
ARG GIT_USER
ARG GIT_TOKEN_FILE
ARG MANIFEST_INI_FILE
ARG SITES

COPY pat /usr/local/bin/
COPY docker-entrypoint-build.sh /usr/local/bin/
COPY wp-build.sh /usr/local/bin/

RUN \
  dos2unix /usr/local/bin/* && \
  bash /usr/local/bin/wp-build.sh > /usr/src/wordpress/build-output.txt 2>&1

# -----------------------------------------------------------
#                      STAGE 2
# -----------------------------------------------------------
FROM bu-wordpress-baseline

COPY --from=baseline /usr/src/wordpress/ /usr/src/wordpress/
COPY docker-entrypoint-build.sh /usr/local/bin/
COPY s3proxy.conf /etc/apache2/sites-available/

RUN \
  dos2unix /usr/local/bin/docker-entrypoint-build.sh && \
  chmod a+r /usr/src/wordpress/healthcheck.htm

# Extend the entrypoint script
RUN \
  sed -i "/exec "$@"/i\source docker-entrypoint-build.sh \$@" /usr/local/bin/docker-entrypoint.sh

