#!/bin/bash
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#

generate_dockerfile(){
    local dockerfile version
    version=$1

    image="${version}-fpm-alpine"

    dockerfile=./${version}/Dockerfile
    cat > ${dockerfile} <<TEMPLATE
#
# This file is auto-generated by update.sh
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#
ARG ALPINE_VERSION

FROM php:${image}\${ALPINE_VERSION}

ARG TZ=UTC
ARG PHP_EXTS="pdo_mysql pdo_pgsql intl opcache bcmath"
ARG APK_BASE="bash git vim"
ARG APK_EXTRA
ARG PHP_LIBS
ARG COMPOSER_VERSION=2

ARG OFFENBACH_VERSION
ARG OFFENBACH_FILENAME
ARG OFFENBACH_INSTALL_DIR=/usr/bin

LABEL author="Yannoff <https://github.com/yannoff>" \\
      description="PHP-FPM with basic php extensions and composer" \\
      license="MIT"

ENV MUSL_LOCPATH /usr/local/share/i18n/locales/musl
# Fix ICONV library implementation
# @see https://github.com/docker-library/php/issues/240
ENV LD_PRELOAD /usr/local/lib/preloadable_libiconv.so

# When the container is run as an unknown user (e.g 1000), COMPOSER_HOME defaults to /.composer
ENV COMPOSER_HOME /.composer
ENV PATH \$COMPOSER_HOME/vendor/bin:\$PATH

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

RUN \\
    BUILD_DEPS="autoconf cmake coreutils gcc libc-dev make patch"; \\
    \\
    echo -e "\\033[01m******************************* Build arguments ******************************\\033[00m"; \\
    echo -e "\\033[01mTZ:\\033[01;33m \${TZ}\\033[00m"; \\
    echo -e "\\033[01mAPK_BASE:\\033[01;33m \${APK_BASE}\\033[00m"; \\
    echo -e "\\033[01mAPK_EXTRA:\\033[01;33m \${APK_EXTRA}\\033[00m"; \\
    echo -e "\\033[01mPHP_EXTS:\\033[01;33m \${PHP_EXTS}\\033[00m"; \\
    echo -e "\\033[01mPHP_LIBS:\\033[01;33m \${PHP_LIBS}\\033[00m"; \\
    echo -e "\\033[01mCOMPOSER_VERSION:\\033[01;33m \${COMPOSER_VERSION}\\033[00m"; \\
    echo -e "\\033[01mOFFENBACH_VERSION:\\033[01;33m \${OFFENBACH_VERSION}\\033[00m"; \\
    echo -e "\\033[01mOFFENBACH_FILENAME:\\033[01;33m \${OFFENBACH_FILENAME}\\033[00m"; \\
    echo -e "\\033[01mOFFENBACH_INSTALL_DIR:\\033[01;33m \${OFFENBACH_INSTALL_DIR}\\033[00m"; \\
    echo -e "\\033[01m******************************************************************************\\033[00m"; \\
    \\
    # Install basic packages
    apk add --update tzdata \${APK_BASE} \${APK_EXTRA} && \\
    \\
    # Keep a list of installed packages for after-cleanup restore
    export installed=\$(apk info | xargs); \\
    \\
    # Install temporary build dependencies
    apk add --no-cache --virtual build-deps \${BUILD_DEPS} && \\
    \\
    # Install PHP extensions
    install-php-extensions @composer-\${COMPOSER_VERSION} \${PHP_EXTS} && \\
    \\
    # Install support for locales
    # @see https://github.com/gliderlabs/docker-alpine/issues/144
    apk add --no-cache --virtual .locale-run-deps libintl && \\
    apk add --no-cache --virtual .locale-build-deps cmake make musl-dev gcc gettext-dev && \\
    cd /tmp && curl --output musl-locales-master.zip https://codeload.github.com/rilian-la-te/musl-locales/zip/master && \\
    unzip musl-locales-master.zip && cd musl-locales-master; \\
    cmake . && make && make install; \\
    cd .. && rm -rf /tmp/musl-locales-master*; \\
    \\
    # Fix ICONV library implementation
    # @see https://github.com/docker-library/php/issues/240
    # (could possibly be replaced by:
    #   apk add gnu-libiconv --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted; \\
    # @see https://github.com/wallabag/docker/pull/158/files
    # )
    apk add --no-cache --virtual .iconv-build-deps file libtool && \\
    curl -sSL http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz | tar -xz -C . && \\
    cd libiconv-1.14 && \\
    ./configure --prefix=/usr/local && \\
    curl -sSL https://raw.githubusercontent.com/mxe/mxe/7e231efd245996b886b501dad780761205ecf376/src/libiconv-1-fixes.patch | patch -p1 -u  && \\
    make && make install && \\
    libtool --finish /usr/local/lib; \\
    cd .. && \\
    rm -rf libiconv-1.14; \\
    \\
    # Use VIM for VI (instead of the poorly implemented BusyBox equivalent)
    rm /usr/bin/vi && ln -s /usr/bin/vim /usr/bin/vi && \\
    \\
    # Configure PHP Runtime & system timezone
    { rm /etc/localtime || true; } && ln -s /usr/share/zoneinfo/\${TZ} /etc/localtime && \\
    echo "[Date]" >> /usr/local/etc/php/conf.d/datetime.ini && \\
    echo "date.timezone = \${TZ}" >> /usr/local/etc/php/conf.d/datetime.ini && \\
    \\
    # Ensure the COMPOSER_HOME directory is accessible to all users
    mkdir \$COMPOSER_HOME && chmod 0777 \$COMPOSER_HOME; \\
    \\
    # Install offenbach
    url=https://github.com/yannoff/offenbach/releases/latest/download/install.sh && \\
    curl -SL -s -o - \${url} | bash && \\
    \\
    # Install on-demand global PHP packages, if appropriate
    if [ -n "\${PHP_LIBS}" ]; \\
    then \\
        composer global require \${PHP_LIBS}; \\
    fi; \\
    # Cleanup:
    # - remove build dependencies
    # - restore installed packages (avoid collision with build deps)
    apk del --no-cache build-deps .locale-build-deps .iconv-build-deps; \\
    \\
    # Restore base installed packages, prevents accidental removal by build-deps cleanup
    # @see https://github.com/yannoff/docker-php-fpm/issues/28
    apk add --no-cache \${installed};
TEMPLATE

}

if [ $# -eq 0 ]
then
    # If no version specified, update all
    set -- 5.5 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2-rc
fi

for v in "$@"
do
    printf "Generating dockerfile for version %s..." ${v}
    mkdir -p $v 2>/dev/null
    generate_dockerfile $v
    printf "\033[01;32mOK\033[00m\n"
done

latest=$(ls [0-9]* -d | cat | tail -n 1)
printf "\nLinking latest image directory to version %s..." ${latest}
rm latest
ln -s ${latest} latest && printf "\033[01;32mOK\033[00m"
echo
