#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.4

# persistent / runtime deps
ENV PHPIZE_DEPS \
		autoconf \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c \
		git

RUN apk add --no-cache --virtual .persistent-deps \
		ca-certificates \
		curl \
		tar \
		xz \
		bash

# ensure www user exists
RUN set -x \
	&& addgroup -g 82 -S www \
	&& adduser -u 82 -D -S -G www www
# 82 is the standard uid/gid for "www" in Alpine
# http://git.alpinelinux.org/cgit/aports/tree/main/apache2/apache2.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/lighttpd.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/nginx-initscripts/nginx-initscripts.pre-install?h=v3.3.2

ENV PHP_CONF_DIR /usr/local/etc
RUN mkdir -p $PHP_CONF_DIR/conf.d

##<autogenerated>##
ENV PHP_EXTRA_CONFIGURE_ARGS --enable-maintainer-zts
##</autogenerated>##

ENV GPG_KEYS 0BD78B5F97500D450838F95DFE857D9A90D90EC1 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3

ENV PHP_VERSION 5.6.26
ENV PHP_FILENAME php-5.6.26.tar.xz
ENV PHP_SHA256 203a854f0f243cb2810d1c832bc871ff133eccdf1ff69d32846f93bc1bef58a8

RUN set -xe \
	&& apk add --no-cache --virtual .fetch-deps \
		gnupg \
	&& mkdir -p /usr/src \
	&& cd /usr/src \
	&& curl -fSL "https://secure.php.net/get/$PHP_FILENAME/from/this/mirror" -o php.tar.xz \
	&& echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c - \
	&& curl -fSL "https://secure.php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o php.tar.xz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done \
	&& gpg --batch --verify php.tar.xz.asc php.tar.xz \
	&& rm -r "$GNUPGHOME" \
	&& apk del .fetch-deps

COPY docker-php-source /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-php-source
 
COPY docker-php-source /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-php-source
RUN set -xe \
	&& apk add --no-cache --virtual .build-deps \ 
		$PHPIZE_DEPS \
		curl-dev \
		libedit-dev \
		libxml2-dev \
		openssl-dev \
		sqlite-dev \
		libvpx-dev \
		libpng-dev \ 
		libmcrypt-dev \ 
		libevent-dev \
		jpeg-dev \ 
		freetype-dev \
		gettext-dev \
	\
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& ./configure \
		--with-config-file-path="$PHP_CONF_DIR" \
		--with-config-file-scan-dir="$PHP_CONF_DIR/conf.d" \
		\
		--disable-cgi \
		\
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
		\
		--with-libedit \  
		--enable-fpm \
		--with-fpm-user=www \  
		--with-fpm-group=www \  
		--with-pdo-mysql \  
		--with-pdo-sqlite \  
		--with-iconv-dir \
		--with-freetype-dir \
		--with-jpeg-dir \
		--with-png-dir \
		--with-zlib \
		--with-libxml-dir=/usr \
		--enable-xml \
		--disable-rpath \
		--enable-bcmath \
		--enable-shmop \
		--enable-sysvsem \
		--enable-inline-optimization \
		--with-curl \
		--enable-mbregex \
		--with-mcrypt \
		--with-gd \
		--enable-gd-native-ttf \
		--with-openssl \
		--with-mhash \
		--enable-pcntl \
		--enable-sockets \
		--with-xmlrpc \
		--enable-zip \
		--enable-soap \
		--without-pear \
		--with-gettext \
		--disable-fileinfo \
		--enable-phpdbg-debug \
		--enable-debug \
		--enable-opcache \
		\
		$PHP_EXTRA_CONFIGURE_ARGS \
	&& make -j"$(getconf _NPROCESSORS_ONLN)" \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	\
	&& cd /tmp && git clone https://github.com/phalcon/cphalcon.git \
	&& cd /tmp/cphalcon/build \
	&& ./install \
	&& rm -rf /tmp/* \
	&& echo "extension=phalcon.so" > $PHP_CONF_DIR/conf.d/phalcon.ini \
	\
	&& cd /tmp && git clone --depth=1 https://github.com/phpredis/phpredis.git \
	&& cd /tmp/phpredis \
	&& phpize && ./configure && make && make install \
	&& echo "extension=redis.so" > $PHP_CONF_DIR/conf.d/redis.ini \
	&& rm /tmp/phpredis -rf \
	\
	&& docker-php-source delete \
	\
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }'; \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --no-cache --virtual .php-rundeps $runDeps \
	\
	&& apk del .build-deps \
	&& rm /usr/src/* -rf

COPY docker-php-ext-* /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-php-*  

# Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === 'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" 

WORKDIR /www

# PHP 5.x don't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
RUN set -ex \
	&& cd /usr/local/etc \  
	&& mkdir php-fpm.d \ 
	&& echo '' > php-fpm.d/php-fpm.conf \
	{ \
		echo 'include=etc/php-fpm.d/*.conf'; \ 
		echo '[global]'; \
		echo ; \
		echo 'log_level = notice'; \
		echo ';error_log = /var/log/fpm-error.log'; \ 
		echo '; if we send this to /proc/self/fd/1, it never appears'; \
		echo 'access.log = /proc/self/fd/2'; \ 
		echo 'daemonize = no'; \ 
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
		echo ; \
		echo '[www]'; \ 
		echo ';access.log = var/log/fpm-access.log'; \ 
		echo 'access.format = "%R - %u %t'; \"%m %r%Q%'q\" %s %f %{mili}d %{kilo}M %C%%"'; \ 
		echo 'user = www'; \
		echo 'group = www'; \ 
		echo ; \
		echo 'listen = [::]9000'; \ 
		echo 'pm = dynamic'; \ 
		echo 'pm.max_requests = 2000'; \
		echo 'pm.max_children = 200'; \
		echo 'pm.start_servers = 5'; \
		echo 'pm.min_spare_servers = 5'; \
		echo 'pm.max_spare_servers = 10'; \ 
		echo ; \
		echo 'clear_env = no'; \ 
		echo 'rlimit_files = 1048576'; \
		echo 'request_terminate_timeout = 60'; \
		echo 'request_slowlog_timeout = 10s'; \
		echo 'request_slowlog_timeout = 1'; \
		echo 'slowlog = var/log/php-slow.log'; \ 
	} | tee php-fpm.conf

# PHP config
ADD php.ini    		$PHP_CONF_DIR/php.ini
ADD php-fpm.conf    $PHP_CONF_DIR/php-fpm.conf  

EXPOSE 9000
CMD ["php-fpm"]
##</autogenerated>##