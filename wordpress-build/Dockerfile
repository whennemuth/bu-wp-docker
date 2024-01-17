
ARG DOCKER_REGISTRY

# -----------------------------------------------------------
#                      STAGE 1
# -----------------------------------------------------------
FROM debian:12-slim AS baseline

ARG GIT_USER
ARG GIT_PAT
ARG MANIFEST_INI_FILE
ARG REPOS

RUN \
  apt update -y && \
  apt upgrade -y && \
  apt install git wget dos2unix xxd -y && \
  mkdir -p /tmp/repos

COPY wp-build.sh /usr/local/bin/

# Increment the integer here to employ the cache, but only up to this point so that the wp build will rerun.
ARG CACHEBUST=1

RUN bash /usr/local/bin/wp-build.sh 2>&1 | tee /tmp/repos/build-output.txt

COPY docker-entrypoint-build.sh /usr/local/bin/

# -----------------------------------------------------------
#                      STAGE 2
# -----------------------------------------------------------
FROM ${DOCKER_REGISTRY}/bu-wordpress-baseline

COPY --from=baseline /tmp/repos/ /usr/src/wordpress/
COPY docker-entrypoint-build.sh /usr/local/bin/
COPY s3proxy.conf /etc/apache2/sites-available/

# Extend the entrypoint script
RUN \
  sed -i "/exec "$@"/i\source docker-entrypoint-build.sh \$@" /usr/local/bin/docker-entrypoint.sh

