FROM bu-wordpress-baseline AS baseline
ARG GIT_USER
ARG GIT_TOKEN_FILE
ARG MANIFEST_INI_FILE
ARG SITES
COPY pat /usr/local/bin/
COPY wp-build.sh /usr/local/bin/
RUN \
  dos2unix /usr/local/bin/* && \
  bash /usr/local/bin/wp-build.sh > /usr/src/wordpress/build-output.txt 2>&1

FROM bu-wordpress-baseline
COPY --from=baseline /usr/src/wordpress/ /usr/src/wordpress/