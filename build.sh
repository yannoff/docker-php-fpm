#!/bin/bash
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#

image=yannoff/php-fpm

build_and_push(){
    local version=$1 tag=$2
    [ -z ${tag} ] && tag=${version}-fpm-alpine
    cd ${version}
    docker pull php:${version}
    docker build -t ${image}:${tag} . && docker push ${image}:${tag}
    docker tag ${image}:${tag} ${image}:${version} && docker push ${image}:${version}
    docker rmi ${image}:${version} ${image}:${tag} php:${version}
    cd -
    printf "Building image \033[01m%s:%s\033[00m ...\033[01;32mOK\033[00m\n" "${image}" "$tag"
}

if [ $# -eq 0 ]
then
    # If no version specified, build and push all versions
    set -- 5.5 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1-rc latest
fi

printf "\033[01mUpdating %s ...\033[00m\n" "mlocati/php-extension-installer"
docker pull mlocati/php-extension-installer

for v in "$@"
do
    printf "\033[01mBuilding image %s version %s...\033[00m\n" "${image}" "${v}"
    build_and_push ${v}
done
