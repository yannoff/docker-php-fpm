#!/bin/bash
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#

image=yannoff/php-fpm
logfile=./build.log

#
# Get the latest version number
#
# Usage: v=$(get_latest_numver)
#
get_latest_numver(){
    ls -l latest | awk '{ print $NF; }'
}

#
# Build and push the given image version
#
# Usage: build_and_push <version> [<tag>]
#
build_and_push(){
    local version=$1 tag=$2 args latest

    # If no custom tag provided, use <version>-fpm-alpine
    [ -z ${tag} ] && tag=${version}-fpm-alpine

    printf "\033[01mProcessing version %s...\033[00m\n" "${version}"

    # Enter the version sub-directory
    cd ${version}
    printf "\033[01mPulling php:%s base image...\033[00m\n" "${tag}"

    # Cleanup previous log file
    rm ${logfile}

    # Ensure the original php image is up to date
    docker pull php:${tag}

    # Build & push yannoff/php-fpm:<version>-fpm-alpine image
    printf "\033[01mBuilding image %s:%s...\033[00m\n" "${image}" "${tag}"
    # Fetch build arguments from config file
    bargs=()
    while IFS= read -r line
    do
        bargs+=(--build-arg "${line}")
    done < ../.build-args
    docker build "${bargs[@]}" -t ${image}:${tag} . 2>&1 >>${logfile} && docker push ${image}:${tag}
    # Get back to the top-level directory
    cd -

    # Create & push the yannoff/php-fpm:<version> shortcut alias
    printf "\033[01mCreating shortcut image %s:%s...\033[00m\n" "${image}" "${version}"
    docker tag ${image}:${tag} ${image}:${version} && docker push ${image}:${version}

    # If the built version is the latest, then push the yannoff/php-fpm:latest alias
    latest=$(get_latest_numver)
    if [ "${version}" == "${latest}" ]
    then
        printf "\033[01mCreating shortcut image %s:latest (=> %s)...\033[00m\n" "${image}" "${version}"
        docker tag ${image}:${version} ${image}:latest && docker push ${image}:latest
    fi

    # Run a basic offenbach smoke test
    printf "\033[01mRunning basic smoke test: \033[00m%s\n" "offenbach --version"
    docker run --rm ${image}:${tag} offenbach --version

    # Clean all local images: yannoff/php-fpm:<version> yannoff/php-fpm:<version>-fpm-alpine php:<version>
    printf "\033[01mCleaning assets...\033[00m\n"
    docker rmi ${image}:${version} ${image}:${tag} php:${tag}

    printf "Building image \033[01m%s:%s\033[00m ...\033[01;32mOK\033[00m\n" "${image}" "$tag"
}

# If no version specified, build and push all versions
if [ $# -eq 0 ]
then
    set -- 5.5 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1
fi

# Ensure the php extension installer image is up to date
printf "\033[01mUpdating %s ...\033[00m\n" "mlocati/php-extension-installer"
docker pull mlocati/php-extension-installer

# Process each version
for v in "$@"
do
    # The "latest" tag must be handled specifically
    if [ "${v}" == "latest" ]
    then
        build_and_push ${v} latest
    else
        build_and_push ${v}
    fi
done
