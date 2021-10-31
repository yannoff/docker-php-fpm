#!/bin/bash
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#

image=yannoff/php-fpm
logfile=./build.log

get_latest_numver(){
    ls -l latest | awk '{ print $NF; }'
}

build_and_push(){
    local version=$1 tag=$2 latest
    [ -z ${tag} ] && tag=${version}-fpm-alpine
    printf "\033[01mProcessing version %s...\033[00m\n" "${version}"
    cd ${version}
    printf "\033[01mPulling php:%s base image...\033[00m\n" "${tag}"
    docker pull php:${tag}
    printf "\033[01mBuilding image %s:%s...\033[00m\n" "${image}" "${tag}"
    docker build -t ${image}:${tag} . 2>&1 >>${logfile} && docker push ${image}:${tag}
    cd -
    printf "\033[01mCreating shortcut image %s:%s...\033[00m\n" "${image}" "${version}"
    docker tag ${image}:${tag} ${image}:${version} && docker push ${image}:${version}
    latest=$(get_latest_numver)
    if [ "${version}" == "${latest}" ]
    then
        printf "\033[01mCreating shortcut image %s:latest (=> %s)...\033[00m\n" "${image}" "${version}"
        docker tag ${image}:${version} ${image}:latest && docker push ${image}:latest
    fi
    printf "\033[01mCleaning assets...\033[00m\n"
    docker rmi ${image}:${version} ${image}:${tag} php:${tag}
    printf "Building image \033[01m%s:%s\033[00m ...\033[01;32mOK\033[00m\n" "${image}" "$tag"
}

if [ $# -eq 0 ]
then
    # If no version specified, build and push all versions
    set -- 5.5 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1-rc
fi

printf "\033[01mUpdating %s ...\033[00m\n" "mlocati/php-extension-installer"
docker pull mlocati/php-extension-installer

rm ${logfile}

for v in "$@"
do
    if [ "${v}" == "latest" ]
    then
        build_and_push ${v} latest
    else
        build_and_push ${v}
    fi
done
