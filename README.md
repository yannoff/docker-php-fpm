# yannoff/docker-php-fpm

Home for [yannoff/php-fpm dockerhub repository](https://hub.docker.com/repository/docker/yannoff/php-fpm "dockerhub") sources.

A [PHP-FPM](http://php.net/manual/fr/install.fpm.php "PHP FastCGI Process Manager") [docker](https://www.docker.com/ "docker") image based on [Alpine](https://alpinelinux.org/ "Alpine Linux"), with [composer](https://getcomposer.org/ "composer") and [offenbach](https://github.com/yannoff/offenbach) installed.

## Available tags

- [8.1-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/8.1/Dockerfile)
, [8.1](https://github.com/yannoff/docker-php-fpm/blob/master/8.1/Dockerfile)
- [8.0-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/8.0/Dockerfile)
, [8.0](https://github.com/yannoff/docker-php-fpm/blob/master/8.0/Dockerfile)
- [7.4-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.4/Dockerfile)
, [7.4](https://github.com/yannoff/docker-php-fpm/blob/master/7.4/Dockerfile)
- [7.3-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.3/Dockerfile)
, [7.3](https://github.com/yannoff/docker-php-fpm/blob/master/7.3/Dockerfile) <sup>**(1)**</sup>
- [7.2-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.2/Dockerfile)
, [7.2](https://github.com/yannoff/docker-php-fpm/blob/master/7.2/Dockerfile) <sup>**(1)**</sup>
- [7.1-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.1/Dockerfile)
, [7.1](https://github.com/yannoff/docker-php-fpm/blob/master/7.1/Dockerfile) <sup>**(1)**</sup>
- [7.0-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.0/Dockerfile)
, [7.0](https://github.com/yannoff/docker-php-fpm/blob/master/7.0/Dockerfile) <sup>**(1)**</sup>
- [5.6-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/5.6/Dockerfile)
, [5.6](https://github.com/yannoff/docker-php-fpm/blob/master/5.6/Dockerfile) <sup>**(1)**</sup>
- [5.5-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/5.5/Dockerfile)
, [5.5](https://github.com/yannoff/docker-php-fpm/blob/master/5.5/Dockerfile) <sup>**(1)**</sup> <sup>**(2)**</sup>

> <sup>**(1)**</sup> _Those PHP versions have now reached their [EOL](https://www.php.net/eol.php)._<br/>
> <sup>**(2)**</sup> _[yamltools](https://github.com/yannoff/yamltools) version frozen to `1.3.3` (see [yamltools#0abfdf7](https://github.com/yannoff/yamltools/commit/0abfdf7c727db62062a24d2e3ec351d38abcd3f6))._

## Usage

- [Dynamically build images](#building-custom-images) for a fine-tuned docker stack
- [Use pre-compiled images](#using-base-images) to run on-the-fly, one-shot commands

### Building custom images

_Dynamic builds allow for flexible, fine-tuned and featherweight images._<br/>
_The recommended way is to [use the repository URL](https://docs.docker.com/engine/reference/commandline/build/#git-repositories) as build context._


_**Example:** Integration in a [docker-compose](https://docs.docker.com/compose/compose-file/) stack_

- PHP version `8.0`
- `gd` and `imap` extensions
- `patch` extra package install
- `Europe/Rome` as timezone
- `laravel/installer` as a composer global package
- `preview` version of composer

```yaml
# docker-compose.yaml
fpm:
    build:
        context: https://github.com/yannoff/docker-php-fpm.git#:8.0
        args:
            TZ: Europe/Rome
            PHP_EXTS: gd imap
            APK_EXTRA: patch
            PHP_LIBS: laravel/installer
            COMPOSER_VERSION: preview
```

*Alternatively, building from the command-line:*

```bash
docker                                     \
    build                                  \
    -t php8.0                              \
    --build-arg TZ="Europe/Rome"           \
    --build-arg PHP_EXTS="gd imap"         \
    --build-arg APK_EXTRA=patch            \
    --build-arg PHP_LIBS=laravel/installer \
    --build-arg COMPOSER_VERSION=preview   \
    git@github.com:yannoff/docker-php-fpm.git#:8.0
```


#### Build arguments reference

The following [build arguments](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg) are available:

| Build arg  | Description                                                                                  | Defaults
|---         |---                                                                                           |---
| `TZ`       | The timezone to use for the container                                                        | `UTC`
| `PHP_EXTS` | PHP extensions to be installed at build time <sup>**(3)**</sup>                              | `pdo_mysql pdo_pgsql intl opcache bcmath`
| `APK_BASE` | Base [alpine](https://pkgs.alpinelinux.org/packages) packages to be installed at build time  | `bash git vim`
| `APK_EXTRA`| Extra [alpine](https://pkgs.alpinelinux.org/packages) packages to be installed at build time | -
| `PHP_LIBS` | PHP libraries to be installed as composer global dependencies                                | -
| `COMPOSER_VERSION` | Major composer version to be installed                                               | `2`


> **<sup>(3)</sup>** _See the [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer#supported-php-extensions) repository for the full list of supported extensions._


### Using base images

_On the other hand, the base pre-compiled images from [dockerhub](https://hub.docker.com/repository/docker/yannoff/php-fpm "dockerhub") may be convenient to [run](https://docs.docker.com/engine/reference/run/) php or composer commands on the fly, providing a minimal PHP ecosystem._

_**Example:** Creating a new [laravel](https://github.com/laravel/laravel) empty project_

```
docker                  \
    run                 \
    --rm                \
    -it                 \
    -u $UID:$GID        \
    -w /src             \
    -v $PWD:/src        \
    yannoff/php-fpm:8.0 \
    composer create-project --ignore-platform-reqs laravel/laravel acme
```

> _Since the base image may not contain all of the required PHP extensions, the `--ignore-platform-reqs` switch is recommended_

#### Pre-compiled images defaults

_Pre-compiled images are built with the following default values:_

| Build arg  | Value
|---         |---   
| `TZ`       | `Europe/Paris`
| `PHP_EXTS` | `intl opcache`
| `APK_BASE` | `bash git vim`
| `COMPOSER_VERSION` | `2`

## Helper scripts

A set of helper scripts are available in the [bin](bin) directory.

Each of them allows to run any php command on-the-fly, including `composer` or `offenbach` commands.

_For instance:_

```
bin/php8.1 offenbach install
```

> *All helpers must reside in the same directory, since the [`php`](bin/php) script is the main entrypoint for all versions.*


## Credits

Licensed under the [MIT License](https://github.com/yannoff/docker-php-fpm/blob/master/LICENSE).

This project uses the awesome [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer) script for PHP extensions install.
