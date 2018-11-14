FROM debian:jessie

MAINTAINER Cesar Romero <cromero@digitalorigin.com>

# phpize deps
RUN apt-get update -y --fix-missing && apt-get install -y \
        autoconf \
        file \
        g++ \
        gcc \
        libc-dev \
        make \
        pkg-config \
        re2c \
        libpng-dev

# persistent / runtime deps
RUN apt-get install -y \
        ca-certificates \
        curl \
        libedit2 \
        libsqlite3-0 \
        libxml2 \
        -qq npm \
    --no-install-recommends

# Create symbolic link for the npm install
RUN ln -s /usr/bin/nodejs /usr/bin/node

# Install npm 2 version.
RUN npm install -g npm@latest-2

# Install specific node version.
RUN npm install -g n && n 4.*

# Bower install
RUN npm install --global bower

ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d

##<autogenerated>##
RUN apt-get install -y apache2-bin apache2.2-common --no-install-recommends

RUN rm -rf /var/www/html && mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html && chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html

# Apache + PHP requires preforking Apache for best results
RUN a2dismod mpm_event && a2enmod mpm_prefork

RUN mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.dist && rm /etc/apache2/conf-enabled/* /etc/apache2/sites-enabled/*
COPY ./config/apache2.conf /etc/apache2/apache2.conf
# it'd be nice if we could not COPY apache2.conf until the end of the Dockerfile, but its contents are checked by PHP during compilation

ENV PHP_EXTRA_BUILD_DEPS apache2-dev
ENV PHP_EXTRA_CONFIGURE_ARGS --with-apxs2
##</autogenerated>##

#ENV GPG_KEYS A917B1ECDA84AEC2B568FED6F50ABC807BD5DCD0
ENV GPG_KEYS 1A4E8B7277C42E53DBA9C7B9BCAA30EA9C0D5763 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3

ENV PHP_VERSION 7.0.32
ENV PHP_FILENAME php-7.0.32.tar.xz
ENV PHP_SHA256 ff6f62afeb32c71b3b89ecbd42950ef6c5e0c329cc6e1c58ffac47e6f1f883c4

RUN set -xe \
    && buildDeps=" \
        $PHP_EXTRA_BUILD_DEPS \
        libcurl4-openssl-dev \
        libreadline6-dev \
        librecode-dev \
        libedit-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libmcrypt-dev \
        zlib1g-dev \
        libxrender1 \
        libxtst6 \
        libfontconfig1 \
        vim \
        cron \
        rsyslog \
        git \
        xz-utils \
        libc-client-dev \
        libkrb5-dev \
        rsync \
    " \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && curl -fSL "http://php.net/get/$PHP_FILENAME/from/this/mirror" -o "$PHP_FILENAME" \
    && echo "$PHP_SHA256 *$PHP_FILENAME" | sha256sum -c - \
    && curl -fSL "http://php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o "$PHP_FILENAME.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && for key in $GPG_KEYS; do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done \
    && gpg --batch --verify "$PHP_FILENAME.asc" "$PHP_FILENAME" \
    && rm -r "$GNUPGHOME" "$PHP_FILENAME.asc" \
    && mkdir -p /usr/src/php \
    && tar -xf "$PHP_FILENAME" -C /usr/src/php --strip-components=1 \
    && rm "$PHP_FILENAME" \
    && cd /usr/src/php \
    && ./configure \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        $PHP_EXTRA_CONFIGURE_ARGS \
        --disable-cgi \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
        --enable-mysqlnd \
        --enable-soap \
        --enable-sockets \
	    --enable-ftp \
        --with-curl \
        --with-libedit \
        --with-openssl \
        --with-zlib \
        --with-imap \
        --with-kerberos \
        --with-imap-ssl \
        --enable-pcntl \
    && make -j"$(nproc)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
    && make clean

COPY ./docker-php-ext-* /usr/local/bin/

##<autogenerated>##
COPY ./apache2-foreground /usr/local/bin/

RUN docker-php-ext-install mysqli pdo pdo_mysql mbstring mcrypt iconv zip gd
RUN pecl install channel://pecl.php.net/apcu_bc-1.0.3
RUN docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini
RUN docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini
RUN a2enmod rewrite ssl macro headers
RUN usermod -u 1000 www-data
RUN mkdir -p /var/www/html
RUN apt-get update
RUN yes | apt-get upgrade
ENV TERM xterm
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

RUN cd /var/www && git clone -b master https://github.com/phpredis/phpredis.git && cd /var/www/phpredis && phpize && ./configure && make && make install
RUN echo "extension=redis.so" > /usr/local/etc/php/php.ini

# Memory Limit
RUN echo "memory_limit=2048M" > /usr/local/etc/php/conf.d/memory-limit.ini

# Composer global install
RUN composer global require hirak/prestissimo

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /var/www

# Common alias
RUN echo "alias ls='ls --color=auto'" >> .bashrc
RUN echo "alias ll='ls -halF'" >> .bashrc

EXPOSE 80
CMD ["apache2-foreground"]
