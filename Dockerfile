FROM php:7.0-fpm-alpine

LABEL author="Yannoff <https://github.com/yannoff>" \
      description="PHP-FPM with basic php extensions and composer" \
      license="MIT"

# Install basic PHP extensions
RUN apk update \
	&& apk add tzdata git postgresql-dev icu-dev curl-dev libxml2-dev bash \
	&& docker-php-ext-install pdo pdo_mysql pdo_pgsql intl curl json opcache xml bcmath

# Install composer
RUN apk add perl-digest-hmac \
    && curl https://getcomposer.org/installer -o composer-setup.php \
	# TODO: Retrieve setup signature online:
	# EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
	&&  [ "`shasum -a 384 composer-setup.php | awk '{ printf "%s",$1; }'`" = "544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061" ] \
    && php composer-setup.php --filename=composer --install-dir=/usr/bin \
    && rm composer-setup.php \
    && apk del perl-digest-hmac

# Purge APK cache
RUN rm -v /var/cache/apk/*
