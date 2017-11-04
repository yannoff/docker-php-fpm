FROM php:5.6-fpm-alpine

LABEL author="Yannoff <https://github.com/yannoff>" \
      description="PHP-FPM with basic php extensions and composer" \
      license="MIT"

# Install basic PHP extensions
RUN \
    apk add --update postgresql-dev icu-dev curl-dev libxml2-dev bash && \
    docker-php-ext-install pdo pdo_mysql pdo_pgsql intl curl json opcache xml bcmath

# Install composer
RUN apk add perl-digest-hmac && \
    curl https://getcomposer.org/installer -o composer-setup.php; \
    ACTUAL_SIG=`shasum -a 384 composer-setup.php | awk '{ printf "%s",$1; }'`; \
    EXPECTED_SIG=`curl -s https://composer.github.io/installer.sig | tr -d "\n"`; \
    [ "$ACTUAL_SIG" = "$EXPECTED_SIG" ] && \
    php composer-setup.php --filename=composer --install-dir=/usr/bin && \
    rm composer-setup.php && \
    apk del perl-digest-hmac

# Purge APK cache
RUN rm -v /var/cache/apk/*
