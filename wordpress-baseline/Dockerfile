FROM wordpress:5.4.2-php7.4-apache

# Client utils & tools
RUN \
  apt update && apt upgrade; \
  apt install curl less git vim dos2unix ssl-cert util-linux jq unzip groff -y; \
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
  chmod +x wp-cli.phar; \
  mv wp-cli.phar /usr/local/bin/wp; \
  apt install -y $(apt-cache search mysql-client | head -1 | awk '{print $1}'); \
  docker-php-ext-install pdo pdo_mysql;

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
	./aws/install

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
COPY --chmod=766 shib.conf /etc/apache2/conf-available/
COPY --chmod=700 healthcheck.htm /usr/src/wordpress/
RUN rm /etc/apache2/sites-enabled/000-default.conf

# Custom htaccess file for multisite
COPY --chmod=766 .htaccess /var/www/html/

# Expanded upload limits for php.ini
COPY --chmod=766 uploads.ini /usr/local/etc/php/conf.d/

# Extend the entrypoint script
RUN \
  sed -i "/exec "$@"/i\source docker-entrypoint-baseline.sh \$@" /usr/local/bin/docker-entrypoint.sh
