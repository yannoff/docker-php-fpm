#!/bin/bash
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#

generate_dockerfile(){
    local dockerfile version
    version=$1
    # Handle yamltools version
    # @see https://github.com/yannoff/yamltools/commit/0abfdf7c727db62062a24d2e3ec351d38abcd3f6
    if [ ${version} = "5.5" ]
    then
        offenbach_version=1.2.1
    else
        offenbach_version="\$(git describe --tags --abbrev=0)"
    fi

    case ${version} in
        latest)
            image="fpm-alpine"
            ;;
        [0-9]*)
            image="${1}-fpm-alpine"
            ;;
    esac
    dockerfile=./${version}/Dockerfile
    cat > ${dockerfile} <<TEMPLATE
#
# This file is auto-generated by update.sh
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#

FROM php:${image}

ARG PHP_EXTS="pdo_mysql pdo_pgsql intl opcache bcmath"
ARG APK_ADD

LABEL author="Yannoff <https://github.com/yannoff>" \\
      description="PHP-FPM with basic php extensions and composer" \\
      license="MIT"

ENV MUSL_LOCPATH /usr/local/share/i18n/locales/musl
# Fix ICONV library implementation
# @see https://github.com/docker-library/php/issues/240
ENV LD_PRELOAD /usr/local/lib/preloadable_libiconv.so

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

# Install basic packages & PHP extensions
RUN \\
    BUILD_DEPS="autoconf gcc libc-dev make patch"; \\
    apk add --update bash coreutils git vim \${APK_ADD} && \\
    \\
    # Keep a list of installed packages for after-cleanup restore
    export installed=\$(apk info | xargs); \\
    \\
    # Install temporary build dependencies
    apk add --no-cache --virtual build-deps \${BUILD_DEPS} && \\
    \\
    install-php-extensions \${PHP_EXTS} && \\
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
    # Install composer
    #  - Download composer-setup.php & check for file integrity
    #  - Run composer installation script then remove it
    curl -sSL https://getcomposer.org/installer -o composer-setup.php; \\
    ACTUAL_SIG=\`sha384sum composer-setup.php | awk '{ printf "%s",\$1; }'\`; \\
    EXPECTED_SIG=\`curl -s https://composer.github.io/installer.sig | tr -d "\n"\`; \\
    [ "\$ACTUAL_SIG" = "\$EXPECTED_SIG" ] || echo "[composer] Error: signatures does not match!"; \\
    php composer-setup.php --filename=composer --install-dir=/usr/bin && \\
    rm composer-setup.php && \\
    \\
    # When the container is run as an unknown user (e.g 1000), COMPOSER_HOME defaults to /.composer
    mkdir /.composer && chmod 0777 /.composer; \\
    \\
    # Install offenbach
    cd /tmp && git clone https://github.com/yannoff/offenbach.git && cd offenbach && \\
    # Use the latest release version instead of potentially unstable master
    offenbach_version=${offenbach_version} && git checkout \${offenbach_version} && \\
    ./configure --bindir /usr/local/bin bin/offenbach && make && make install && \\
    cd /tmp && rm -rf offenbach && \\
    \\
    # Install box
    php_vers=\$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;"); \\
    echo "phar.readonly = Off" >> \${PHP_INI_DIR}/php.ini; \\
    if [ \${php_vers} -ge 73 ]; \\
    then \\
        curl -sSL -o /usr/local/bin/box https://github.com/box-project/box/releases/latest/download/box.phar; \\
    else \\
        # composer self-update --1 && \\
        curl -LSs https://box-project.github.io/box2/installer.php | php && \\
        mv box.phar /usr/local/bin/box; \\
    fi && \\
    chmod +x /usr/local/bin/box; \\
    \\
    # Install SATIS
    cd /tmp && \\
    git clone https://github.com/composer/satis.git && \\
    cd satis && \\
    if [ \${php_vers} -lt 73 ]; \\
    then \\
        git checkout f66ff72ce4e788e95827404888fd53b3c9d29f82 && \\
        sed -i 's/vfsStream/vfsstream/' composer.json; \\
    fi; \\
    ### Fix PHP version conflict in 8.0
    rm composer.lock && \\
    composer install --no-dev && \\
    box build && \\
    mv satis.phar /usr/local/bin/satis.phar && \\
    chmod +x /usr/local/bin/satis.phar && \\
    cd .. && \\
    rm -rf satis && \\
    # Remove /tmp/box folder: avoid permission problems since it was created by root
    rmdir /tmp/box; \\
    \\
    # Cleanup:
    # - remove build dependencies
    # - restore installed packages (avoid collision with build deps)
    # - remove C++ header files & PHP source tarball
    apk del --no-cache build-deps .locale-build-deps .iconv-build-deps; \\
    \\
    # Restore base installed packages, prevents accidental removal by build-deps cleanup
    # @see https://github.com/yannoff/docker-php-fpm/issues/28
    apk add --no-cache \${installed}; \\
    \\
    rm -rf  /usr/local/include/*; \\
    rm -rf /usr/src/*;

# Ship satis wrapper script
COPY satis /usr/local/bin/
TEMPLATE

}

if [ $# -eq 0 ]
then
    # If no version specified, update all
    set -- 5.5 5.6 7.0 7.1 7.2 7.3 7.4 8.0
fi

for v in "$@"
do
    printf "Generating dockerfile for version %s..." ${v}
    mkdir -p $v 2>/dev/null
    generate_dockerfile $v
    printf "\033[01;32mOK\033[00m\n"
    printf "Including satis wrapper script...\n"
    cp -v satis ${v}
done

latest=$(ls [0-9]* -d | cat | tail -n 1)
printf "\nLinking latest image directory to version %s..." ${latest}
rm latest
ln -s ${latest} latest

printf "\nCopying latest version to root Dockerfile..."
cp latest/Dockerfile . 2>/dev/null
printf "\033[01;32mOK\033[00m\n"
