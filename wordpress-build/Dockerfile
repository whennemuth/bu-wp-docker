
# -----------------------------------------------------------
#                      STAGE 1
# -----------------------------------------------------------
FROM debian:12-slim AS baseline

ARG GIT_USER
ARG GIT_TOKEN_FILE
ARG MANIFEST_INI_FILE
ARG REPOS

COPY pat /usr/local/bin/
COPY docker-entrypoint-build.sh /usr/local/bin/
COPY wp-build.sh /usr/local/bin/

RUN \
  apt update && \
  apt upgrade && \
  apt install git xxd -y && \
  mkdir -p /tmp/repos

RUN bash /usr/local/bin/wp-build.sh > /tmp/repos/build-output.txt 2>&1

# -----------------------------------------------------------
#                      STAGE 2
# -----------------------------------------------------------
FROM bu-wordpress-baseline

COPY --from=baseline /tmp/repos/ /usr/src/wordpress/
COPY docker-entrypoint-build.sh /usr/local/bin/
COPY s3proxy.conf /etc/apache2/sites-available/

# Extend the entrypoint script
RUN \
  sed -i "/exec "$@"/i\source docker-entrypoint-build.sh \$@" /usr/local/bin/docker-entrypoint.sh

