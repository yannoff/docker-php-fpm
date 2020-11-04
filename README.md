# yannoff/docker-php-fpm

A [PHP-FPM](http://php.net/manual/fr/install.fpm.php "PHP FastCGI Process Manager") [docker](https://www.docker.com/ "docker") image based on [Alpine](https://alpinelinux.org/ "Alpine Linux"), with [composer](https://getcomposer.org/ "composer") and [offenbach](https://github.com/yannoff/offenbach) installed.

## Available tags

- [8.0-rc-fpm-alpine](8.0-rc/Dockerfile)
- [7.4-fpm-alpine](7.4/Dockerfile)
- [7.3-fpm-alpine](7.3/Dockerfile)
- [7.2-fpm-alpine](7.2/Dockerfile)
- [7.1-fpm-alpine](7.1/Dockerfile) <sup>(*)</sup>
- [7.0-fpm-alpine](7.0/Dockerfile) <sup>(*)</sup>
- [5.6-fpm-alpine](5.6/Dockerfile) <sup>(*)</sup>
- [5.5-fpm-alpine](5.5/Dockerfile) <sup>(*)</sup>

> (*) _Those PHP versions have now reached their EOL. This means they are not officially supported anymore._

## Quick Start

### 1. Pull from [dockerhub](https://hub.docker.com/ "dockerhub")

```bash
docker pull yannoff/php-fpm
```

### 2. Run container

Several ways to run the container:

#### 2.1 Standalone:

Ex:


```bash
docker run --rm --name fpm_service -v "/your/web/document/root":/www -p 9000:9001 -w /www yannoff/php-fpm
```

##### Options explained:
- `--name fpm_service` set a name for the container (optional).

    *If no name provided, docker will generate a random one itself.*
- `--rm` tells docker to remove container after stopping (optional).

- `-v "/your/web/document/root":/www` mounts your document root to `/www` directory of the container
    *IMPORTANT NOTE: local path has to be wrapped between double quotes (`"`) for `docker` to recognize it as a directory*

- `-p 9000:9001` port mapping: optionnally map port 9000 used by container to port 9001 on your host machine

    *If no port mapping provided, docker will assign a random free port on host machine.*
    *Note: As `PHP-FPM` is often used as a linked container, for example in association with `NGINX`, there is no real need to expose a specific port on host machine, as docker use its own internal ports to link services between each others.*
- `-w /www` set an alternate container working dir, instead of the default `/server`.

    *Note: this value **should** match the container mounted volume specified via `-v` option.*


#### 2.2 Via [docker-compose](https://github.com/docker/compose "Docker Compose Project"):

```yaml
# docker-compose.yml
fpm:
    image: yannoff/php-fpm
    # Here the exposed port on host machine is left unset, letting docker allocate it automatically to a free available port*
    ports:
        - 9000
    volumes:
        - /your/web/document/root:/www
    working_dir: /www 

```
