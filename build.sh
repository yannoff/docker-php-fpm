#!/bin/bash
#
# @package php/alpine/fpm
# @author  Yannoff <https://github.com/yannoff>
# @license MIT
#

image=yannoff/php-fpm
job=$(basename $0 .sh)

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
# Usage: deploy <version>
#
deploy(){
    local version=${1}
    build ${version} && push ${version} && cleanup ${version}
    return $?
}

#
# Build the given image version
#
# Usage: build <version>
#
build(){
    local args status=1 version=${1}
    local context=${version}/ logfile=${version}/build.log from=${version}-fpm-alpine

    # Cleanup previous log file
    rm ${logfile} 2>/dev/null || true

    # Ensure the original php image is up to date
    printf "\033[01mPulling php:%s base image...\033[00m\n" "${from}"
    docker pull php:${from}

    # Build & push yannoff/php-fpm:<version> image
    printf "\033[01mBuilding image %s:%s...\033[00m\n" "${image}" "${version}"
    # Fetch build arguments from config file
    bargs=()
    while IFS= read -r line
    do
        bargs+=(--build-arg "${line}")
    done < .build-args
    docker buildx build "${bargs[@]}" --no-cache -t ${image}:${version} ${context} 2>&1 >>${logfile}

    status=$?

    # If build succeeded, run a basic offenbach smoke test
    if [ "${status}" -eq 0 ]
    then
        printf "\033[01mRunning basic smoke test: \033[00m%s\n" "offenbach --version"
        docker run --rm ${image}:${version} offenbach --version

        printf "Building image \033[01m%s:%s\033[00m ...\033[01;32mOK\033[00m\n" "${image}" "${version}"
    fi

    return ${status}
}

#
# Push the given image version
#
# Usage: push <version>
#
push(){
    local latest status=0 version=${1}
    local longtag=${version}-fpm-alpine

    # Push yannoff/php-fpm:<version> image
    printf "\033[01mPushing image %s:%s...\033[00m\n" "${image}" "${version}"
    docker push ${image}:${version}
    let status+=$?

    # Create the yannoff/php-fpm:<version>-fpm-alpine alias
    printf "\033[01mCreating shortcut image %s:%s...\033[00m\n" "${image}" "${longtag}"
    docker tag ${image}:${version} ${image}:${longtag}

    # Push yannoff/php-fpm:<version>-fpm-alpine image
    printf "\033[01mPushing image %s:%s...\033[00m\n" "${image}" "${longtag}"
    docker push ${image}:${longtag}
    let status+=$?

    # If the built version is the latest, then push the yannoff/php-fpm:latest alias
    latest=$(get_latest_numver)
    if [ "${version}" == "${latest}" ]
    then
        printf "\033[01mCreating shortcut image %s:latest (=> %s)...\033[00m\n" "${image}" "${version}"
        docker tag ${image}:${version} ${image}:latest
        printf "\033[01mPushing shortcut image %s:latest...\033[00m\n" "${image}"
        docker push ${image}:latest
        let status+=$?
    fi

    return ${status}
}

#
# Remove all local images: yannoff/php-fpm:<version> yannoff/php-fpm:<version>-fpm-alpine php:<version>
#
# Usage: cleanup <version>
#
cleanup(){
    local latest status=0 version=${1}
    local longtag=${version}-fpm-alpine

    printf "\033[01mCleaning assets...\033[00m\n"
    for i in ${image}:${version} ${image}:${longtag} php:${longtag}
    do
        printf "\033[01mCleaning %s image...\033[00m\n" ${i}
        docker rmi ${i}
        let status+=$?
    done

    # If version is the latest, then remove also the yannoff/php-fpm:latest image
    latest=$(get_latest_numver)
    if [ "${version}" == "${latest}" ]
    then
        printf "\033[01mCleaning image %s:latest...\033[00m\n" "${image}"
        docker rmi ${image}:latest
        let status+=$?
    fi

    # Prune docker builder cache
    printf "\033[01mPruning docker builder cache...\033[00m\n"
    docker builder prune --force
    let status+=$?


    return ${status}
}

# If no version specified, build and push all versions
if [ $# -eq 0 ]
then
    set -- $(find . -type d -name '[5-9]\.[0-9]*' | sort | sed 's#^./##' | xargs)
fi

# If a build is implied, ensure the php extension installer image is up to date
if [ "${job}" != "push" ]
then
    printf "\033[01mUpdating %s ...\033[00m\n" "mlocati/php-extension-installer"
    docker pull mlocati/php-extension-installer
fi

# Process each version
for v in "$@"
do
    # Clean assets on interrupt
    trap "cleanup ${v}; exit 0" SIGINT SIGTERM

    printf "\033[01m[%s] Processing version %s...\033[00m\n" "${job}" "${v}"
    ${job} ${v}
done
