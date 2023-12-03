#!/bin/bash

export LANG=C

[[ $EUID != 0 ]] && echo -e "\nThis script must be run with root privileges\n" && exit 1

usage() {
    echo
    echo "usage: $(basename $0) [-r 15.0]"
    echo "       -r      distribution release, default current"
    echo "       -h      displays this message "
    echo
    exit 1
}

while [ -n "$1" ]; do # while loop starts
    case "$1" in
    -r)
        RELEASE="$2"
        shift
        ;;
    -h) usage
        ;;
    --)
        shift # The double dash makes them parameters
        break
        ;;
     *) usage
        ;;
    esac
    shift
done

if [[ -z "$RELEASE" ]]; then
    RELEASE="current"
fi

if [[ -z "$ARCH" ]]; then
    ARCH="aarch64"
fi

DISTR_NAME="slarm64"
SLARM64=${SLARM64:-yes}
PKGS=${PKGS:-no}
TOOLS_PATH="/mnt/shares/linux/slarm64/$DISTR_NAME-$RELEASE/source/tools"

echo
echo "+--------------------------+"
echo "Distribution: $DISTR_NAME"
echo "Release: $RELEASE"
echo "Arch: $ARCH"
echo "+--------------------------+"
echo

sleep 5

fixed_permisions() {
    local DIR="$1"
    [[ -z "$DIR" ]] && exit
    chown -R root:root "$DIR"
    find "$DIR" \
     \( -type d \) \
     -exec chmod 755 {} \; -o \
     \( -type f \) \
     -exec chmod 644 {} \;
}


pushd /tmp/ 2>&1>>/dev/null


if [[ $SLARM64 == yes ]]; then
    if [[ $ARCH == "riscv64" ]]; then
        DISTR="/mnt/shares/linux/slarm64/$DISTR_NAME-$ARCH-$RELEASE/"
        export DISTR_ROOT="/mnt/shares/linux/slarm64/$DISTR_NAME-$ARCH-$RELEASE/"
        export PATH_DISTRO="/mnt/shares/linux/slarm64/$DISTR_NAME-$ARCH-$RELEASE"
        export DISTR_OWNER=${DISTR_OWNER:-"slarm64 $ARCH"}
    else
        DISTR="/mnt/shares/linux/slarm64/$DISTR_NAME-$RELEASE/"
    fi
    echo "| build $DISTR_NAME $RELEASE |"
    pushd $DISTR 2>&1>>/dev/null
    fixed_permisions $DISTR
    sh ${TOOLS_PATH}/build_changelog.sh
    sh ${TOOLS_PATH}/slarm64_generate_files.sh
    popd 2>&1>>/dev/null
fi


if [[ $PKGS == yes ]]; then
    echo "| build $DISTR pkgs |"
    export PATH_DISTRO="/mnt/shares/linux/slackware/packages"
    export DISTR_ROOT="/mnt/shares/linux/slackware/packages/"
    fixed_permisions $DISTR_ROOT
    sh ${TOOLS_PATH}/build_changelog.sh
    sh ${TOOLS_PATH}/slarm64_generate_files.sh
fi


popd 2>&1>>/dev/null
