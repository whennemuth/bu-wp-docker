FROM wordpress:5.4.2-php7.4-apache

# Override this to get a cache miss and force rebuild from scratch
# Example: docker build -t bu-wordpress-baseline --build-arg $(date +'%F-%T') .
ARG CACHE_DATE
ENV CACHE_DATE=${CACHE_DATE:-"2023-06-08-00:00:00"}

# Client utils & tools
RUN \
  apt update && apt upgrade; \
  apt install curl less git vim dos2unix ssl-cert util-linux jq -y; \
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
  chmod +x wp-cli.phar; \
  mv wp-cli.phar /usr/local/bin/wp; \
  apt install -y $(apt-cache search mysql-client | head -1 | awk '{print $1}'); \
  docker-php-ext-install pdo pdo_mysql;

# Igbinary
RUN \
  mkdir -p /usr/src/php/ext \
  && cd /usr/src/php/ext \
  && curl -fsSL https://github.com/igbinary/igbinary/archive/master.tar.gz -o igbinary.tar.gz \
  && mkdir -p igbinary \
  && tar -xf igbinary.tar.gz -C igbinary --strip-components=1 \
  && rm igbinary.tar.gz \
  && docker-php-ext-install igbinary

# Redis 
RUN \
  cd /tmp; \
  git clone https://github.com/phpredis/phpredis.git; \
  cd phpredis; \
  phpize; \
  # SEE: https://github.com/phpredis/phpredis/blob/develop/INSTALL.md
  ./configure --enable-redis-igbinary; \
  make && make install;

# Shibboleth
#   1) Install and enable modules
RUN \
  apt-get -y install libapache2-mod-shib && \
  apache2ctl -M | grep mod_shib && \
  a2enmod auth_basic headers rewrite ssl proxy proxy_http env shib
#   2) Copy and adjust files
COPY --chmod=766 shibboleth2-template.xml /etc/shibboleth/
COPY --chmod=766 attribute-map.xml /etc/shibboleth/
COPY --chmod=777 docker-entrypoint-baseline.sh /usr/local/bin/
COPY --chmod=766 wordpress.conf /etc/apache2/sites-enabled/
COPY --chmod=766 shibboleth.conf /etc/apache2/sites-available/
COPY --chmod=700 healthcheck.htm /usr/src/wordpress/
RUN rm /etc/apache2/sites-enabled/000-default.conf

# Extend the entrypoint script
RUN \
  sed -i "/exec "$@"/i\source docker-entrypoint-baseline.sh \$@" /usr/local/bin/docker-entrypoint.sh