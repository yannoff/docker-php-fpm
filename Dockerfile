#
# This file is auto-generated by update.sh
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#
ARG ALPINE_VERSION=3.13

FROM php:8.1-rc-fpm-alpine${ALPINE_VERSION}

ARG PHP_EXTS="pdo_mysql pdo_pgsql intl opcache bcmath"
ARG APK_ADD
ARG PHP_LIBS

LABEL author="Yannoff <https://github.com/yannoff>" \
      description="PHP-FPM with basic php extensions and composer" \
      license="MIT"

ENV MUSL_LOCPATH /usr/local/share/i18n/locales/musl
# Fix ICONV library implementation
# @see https://github.com/docker-library/php/issues/240
ENV LD_PRELOAD /usr/local/lib/preloadable_libiconv.so

ENV PATH /.composer/vendor/bin:$PATH

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

# Install basic packages & PHP extensions
RUN \
    BUILD_DEPS="autoconf coreutils gcc libc-dev make patch"; \
    apk add --update bash git vim ${APK_ADD} && \
    \
    # Keep a list of installed packages for after-cleanup restore
    export installed=$(apk info | xargs); \
    \
    # Install temporary build dependencies
    apk add --no-cache --virtual build-deps ${BUILD_DEPS} && \
    \
    install-php-extensions ${PHP_EXTS} && \
    \
    # Install support for locales
    # @see https://github.com/gliderlabs/docker-alpine/issues/144
    apk add --no-cache --virtual .locale-run-deps libintl && \
    apk add --no-cache --virtual .locale-build-deps cmake make musl-dev gcc gettext-dev && \
    cd /tmp && curl --output musl-locales-master.zip https://codeload.github.com/rilian-la-te/musl-locales/zip/master && \
    unzip musl-locales-master.zip && cd musl-locales-master; \
    cmake . && make && make install; \
    cd .. && rm -rf /tmp/musl-locales-master*; \
    \
    # Fix ICONV library implementation
    # @see https://github.com/docker-library/php/issues/240
    # (could possibly be replaced by:
    #   apk add gnu-libiconv --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted; \
    # @see https://github.com/wallabag/docker/pull/158/files
    # )
    apk add --no-cache --virtual .iconv-build-deps file libtool && \
    curl -sSL http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz | tar -xz -C . && \
    cd libiconv-1.14 && \
    ./configure --prefix=/usr/local && \
    curl -sSL https://raw.githubusercontent.com/mxe/mxe/7e231efd245996b886b501dad780761205ecf376/src/libiconv-1-fixes.patch | patch -p1 -u  && \
    make && make install && \
    libtool --finish /usr/local/lib; \
    cd .. && \
    rm -rf libiconv-1.14; \
    \
    # Use VIM for VI (instead of the poorly implemented BusyBox equivalent)
    rm /usr/bin/vi && ln -s /usr/bin/vim /usr/bin/vi && \
    \
    # Install composer
    #  - Download composer-setup.php & check for file integrity
    #  - Run composer installation script then remove it
    curl -sSL https://getcomposer.org/installer -o composer-setup.php; \
    ACTUAL_SIG=`sha384sum composer-setup.php | awk '{ printf "%s",$1; }'`; \
    EXPECTED_SIG=`curl -s https://composer.github.io/installer.sig | tr -d "\n"`; \
    [ "$ACTUAL_SIG" = "$EXPECTED_SIG" ] || echo "[composer] Error: signatures does not match!"; \
    php composer-setup.php --filename=composer --install-dir=/usr/bin && \
    rm composer-setup.php && \
    \
    # When the container is run as an unknown user (e.g 1000), COMPOSER_HOME defaults to /.composer
    mkdir /.composer && chmod 0777 /.composer; \
    \
    # Install yamltools standalone (ensure BC with any php version)
    curl -Lo /usr/local/bin/yamltools https://github.com/yannoff/yamltools/releases/latest/download/yamltools && chmod +x /usr/local/bin/yamltools && \
    # Install offenbach
    cd /tmp && git clone https://github.com/yannoff/offenbach.git && cd offenbach && \
    # Use the latest release version instead of potentially unstable master
    offenbach_version=$(git describe --tags --abbrev=0) && git checkout ${offenbach_version} && \
    ./configure --bindir /usr/local/bin bin/offenbach && make && make install && \
    cd /tmp && rm -rf offenbach && \
    \
    # Install on-demand global PHP packages, if appropriate
    if [ -n "${PHP_LIBS}" ]; \
    then \
        composer global require ${PHP_LIBS}; \
    fi; \
    # Cleanup:
    # - remove build dependencies
    # - restore installed packages (avoid collision with build deps)
    apk del --no-cache build-deps .locale-build-deps .iconv-build-deps; \
    \
    # Restore base installed packages, prevents accidental removal by build-deps cleanup
    # @see https://github.com/yannoff/docker-php-fpm/issues/28
    apk add --no-cache ${installed};
