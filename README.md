# yannoff/docker-php-fpm

Home for [yannoff/php-fpm dockerhub repository](https://hub.docker.com/repository/docker/yannoff/php-fpm "dockerhub") sources.

A [PHP-FPM](http://php.net/manual/fr/install.fpm.php "PHP FastCGI Process Manager") [docker](https://www.docker.com/ "docker") image based on [Alpine](https://alpinelinux.org/ "Alpine Linux"), with [composer](https://getcomposer.org/ "composer") and [offenbach](https://github.com/yannoff/offenbach) installed.

## Available tags

- [8.0-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/8.0/Dockerfile)
- [8.0-rc-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/8.0-rc/Dockerfile)
- [7.4-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.4/Dockerfile)
- [7.3-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.3/Dockerfile)
- [7.2-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.2/Dockerfile)
- [7.1-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.1/Dockerfile) <sup>(*)</sup>
- [7.0-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/7.0/Dockerfile) <sup>(*)</sup>
- [5.6-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/5.6/Dockerfile) <sup>(*)</sup>
- [5.5-fpm-alpine](https://github.com/yannoff/docker-php-fpm/blob/master/5.5/Dockerfile) <sup>(*)</sup>

> (*) _Those PHP versions have now reached their EOL. This means they are not officially supported anymore._

## Installed extensions

_By default, each image is bundled with the following extensions:_

- bcmath
- intl
- opcache
- pdo_mysql
- pdo_pgsql


> :bulb: _To use the image with other extensions, consider [building a custom image](https://github.com/yannoff/docker-php-fpm/#2-building-custom-images), using the apposite `PHP_EXTS` [build argument](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg)._

## Usage

### 1. Using the compiled images

Several ways to run the container:

#### 1.1 Standalone:


```bash
docker run --rm --name fpm_service -v "/your/web/document/root":/www -p 9000:9001 -w /www yannoff/php-fpm:7.3-fpm_alpine
```

_See the [apposite docker reference](https://docs.docker.com/engine/reference/run/) for details on `docker run` options._


#### 1.2 Via [docker-compose](https://github.com/docker/compose "Docker Compose Project"):

```yaml
# docker-compose.yml
fpm:
    image: yannoff/php-fpm:7.3-fpm-alpine
    # Here the exposed port on host machine is left unset, letting docker allocate it automatically to a free available port
    ports:
        - 9000
    volumes:
        - /your/web/document/root:/www
    working_dir: /www 

```

_See the [docker compose reference](https://docs.docker.com/compose/compose-file/) for details on the `docker-compose.yaml` file syntax and options._

### 2. Building custom images

_For instance, let's say we want `gd` and `imap` extensions on the `7.3` image._

There are 2 different methods to build the image:


#### 2.1 The classic way

1. Clone this repository or fetch a [zipball](https://github.com/yannoff/docker-php-fpm/archive/master.zip).

2. Build the image with the required extensions:


```bash
$ docker build -t customimage:7.3 --build-arg PHP_EXTS='gd imap' 7.3/
```

#### 2.1 The shortest way

Build directly [using the repository URL](https://docs.docker.com/engine/reference/commandline/build/#git-repositories):

```bash
$ docker build -t customimage:7.3 --build-arg PHP_EXTS='gd imap' git@github.com:yannoff/docker-php-fpm.git#:7.3/
```


## Credits

Licensed under the [MIT License](https://github.com/yannoff/docker-php-fpm/blob/master/LICENSE).

This project uses the awesome [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer) script for PHP extensions install.
