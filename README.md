# yannoff/docker-php-fpm

Home for [yannoff/php-fpm dockerhub repository](https://hub.docker.com/repository/docker/yannoff/php-fpm "dockerhub") sources.

A [PHP-FPM](http://php.net/manual/fr/install.fpm.php "PHP FastCGI Process Manager") [docker](https://www.docker.com/ "docker") image based on [Alpine](https://alpinelinux.org/ "Alpine Linux"), with [composer](https://getcomposer.org/ "composer") and [offenbach](https://github.com/yannoff/offenbach) installed.

## Available tags

- [8.1-rc-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/8.1-rc/Dockerfile)
, [8.1-rc](https://github.com/yannoff/docker-php-fpm/blob/master/8.1-rc/Dockerfile)
- [8.0-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/8.0/Dockerfile)
, [8.0](https://github.com/yannoff/docker-php-fpm/blob/master/8.0/Dockerfile)
- [7.4-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.4/Dockerfile)
, [7.4](https://github.com/yannoff/docker-php-fpm/blob/master/7.4/Dockerfile)
- [7.3-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.3/Dockerfile)
, [7.3](https://github.com/yannoff/docker-php-fpm/blob/master/7.3/Dockerfile)
- [7.2-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.2/Dockerfile) <sup>**(1)**</sup>
- [7.1-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.1/Dockerfile) <sup>**(1)**</sup>
- [7.0-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.0/Dockerfile) <sup>**(1)**</sup>
- [5.6-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/5.6/Dockerfile) <sup>**(1)**</sup>
- [5.5-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/5.5/Dockerfile) <sup>**(1)**</sup> <sup>**(2)**</sup>

> <sup>**(1)**</sup> _Those PHP versions have now reached their EOL.<br/>
> This means they are not [officially supported anymore](https://www.php.net/supported-versions.php) by the [PHP Group](https://www.php.net/credits.php)._<br/>
> <sup>**(2)**</sup> _[yamltools](https://github.com/yannoff/yamltools) version frozen to `1.3.3` (see [yamltools#0abfdf7](https://github.com/yannoff/yamltools/commit/0abfdf7c727db62062a24d2e3ec351d38abcd3f6))._

## Installed extensions & packages

_By default, each image is bundled with the following extensions:_

- bcmath
- intl
- opcache
- pdo_mysql
- pdo_pgsql

_and the base APK packages:_

- vim
- git
- bash


> _[Building a custom image](https://github.com/yannoff/docker-php-fpm/#building-custom-images),_
>_using the apposite [build arguments](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg),_
> _allows a full-control over the installed extensions and let install extra `APK` packages on-demand._


## Usage


Several ways to use the compiled images:

- [running a container standalone](#run-standalone)
- [in a docker compose stack](#or-in-a-docker-stack)

### Run standalone...


```bash
docker run -d --rm --name fpm7 -v /var/www/html:/var/www/html -p 9000:9001 yannoff/php-fpm:7.3
```

_See the [apposite docker reference](https://docs.docker.com/engine/reference/run/) for details on `docker run` options._


### ...or in a docker stack

```yaml
# docker-compose.yaml
fpm:
    image: yannoff/php-fpm:7.3
    # Here the exposed port on host machine is left unset,
    # letting docker allocate it automatically to a free available port
    ports:
        - 9000
    volumes:
        - /your/web/document/root:/www
    working_dir: /www 

```

_See the [docker compose reference](https://docs.docker.com/compose/compose-file/) for details on the `docker-compose.yaml` file syntax and options._

## Building custom images

### Build arguments

The following [build arguments](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg) are available:

| Build arg  | Description                                                             |
|---         |---                                                                      |
| `PHP_EXTS` | PHP extensions to be installed at build time <sup>**(3)**</sup>         |
| `APK_ADD`  | Extra `apk` packages to be installed at build time                      |
| `PHP_LIBS` | PHP libraries to be installed as composer global dependencies           |


**<sup>(3)</sup>** _See the [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer#supported-php-extensions) repository for the full list of supported extensions._

### Examples

There are 2 different methods to build the image:

- [The shortest way](#the-shortest-way)
- [The classic way](#the-classic-way)


#### The shortest way

Build directly [using the repository URL](https://docs.docker.com/engine/reference/commandline/build/#git-repositories):

##### Build from the command line...

_Use case: PHP version 7.3 with `imap` extension only_

```bash
$ docker build -t php73 --build-arg PHP_EXTS=imap git@github.com:yannoff/docker-php-fpm.git#:7.3
```

##### ...or in a docker compose file

_Use case: PHP version 8.0 with `gd` and `imap` extensions, PLUS `tzdata` extra APK package install_

```yaml
# docker-compose.yaml
fpm:
    build:
        context: https://github.com/yannoff/docker-php-fpm.git#:8.0
        args:
            PHP_EXTS: gd imap
            APK_ADD: tzdata
```


#### The classic way

_Use case: PHP version 7.1 with `gd` and `imap` extensions_

1. Clone this repository or fetch a [zipball](https://github.com/yannoff/docker-php-fpm/archive/master.zip).
2. Build the image from the working directory


```bash
$ docker build -t customimage:7.1 --build-arg PHP_EXTS='gd imap' 7.1/
```


## Credits

Licensed under the [MIT License](https://github.com/yannoff/docker-php-fpm/blob/master/LICENSE).

This project uses the awesome [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer) script for PHP extensions install.
