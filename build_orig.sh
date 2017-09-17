#!/bin/bash

_CWD=$(pwd)

#source config.sh || exit 1
#source "packages-minirootfs.conf" || exit 1
#source "n-packages.conf_" || exit 1
#ource "a-packages.conf_" || exit 1
source "ap-packages.conf" || exit 1
#source "l-packages.conf" || exit 1
#source "d-packages.conf" || exit 1
#source "tcl-packages.conf" || exit 1

_BUILD="${_CWD}/slackwarearm64-current/source"
_TXZ="${_CWD}/slackwarearm64-current/slackware"
_SOURCE="${_CWD}/slackware64-current/source"


remove_links() {
    [[ -z "$1" ]] && exit 1
    find "${_BUILD}/$1/" -type l -delete
}

create_links() {
    [[ -z "$1" ]] && exit 1
    ln -sf "${_SOURCE}/$1/"* "${_BUILD}/$1/"
}

patching_files() {
    [[ -z "$1" ]] && exit 1
    local PATCH_FILES=$(find -type f | grep patch | sed 's#.patch$##')
    for pf in "${PATCH_FILES}";do
        pf=$(basename "$pf")
        [[ -z "$pf" ]] && continue
        echo "$pf"
        rm "$pf"
        cp -a "${_SOURCE}/$1/${pf}" "${_BUILD}/$1/"
        patch -p1 --verbose < "${pf}.patch" || exit 1
    done
}

move_pkg() {
    [[ -z "$1" ]] && exit 1
    [[ ! -d "${_TXZ}/$1" ]] && ( mkdir -p "${_TXZ}/$1" || exit 1 )
    mv /tmp/$2-*.txz "${_TXZ}/$1/" || return
}

build() {
    for _PKG in $PKG_LIST;do
        if [[ ! $(echo "${_PKG}" | grep "^#") ]];then
            echo "${_PKG}"
            t=$(echo ${_PKG} | cut -d '/' -f1)
            p=$(echo ${_PKG} | cut -d '/' -f2)
#            if [[ ! $(ls ${_INSTALL}/$t/ | grep "$p-") ]];then
#                removepkg $p
                remove_links "${_PKG}"
                create_links "${_PKG}"
                pushd ${_BUILD}/${_PKG}/
#            $BUILD/$PKG/*.SlackBuild || exit 1
#            export TMP=$TMP/$PKG/
#            $ARCH/*.SlackBuild || exit 1
#            ./*.SlackBuild || exit 1
               patching_files ${_PKG}
#               [[ -x $p.SlackBuild.patch ]] && ( patch -p1 --verbose < *SlackBuild*.patch || exit 1 )
               sed -i 's/\(-slackware\)\(-linux.*\s\)/-unknown\2/g' *.SlackBuild
               sed -i 's/\(-slackware\)\(-linux$\)/-unknown\2/g' *.SlackBuild
               ./*.SlackBuild || exit 1
#                ./arm/build || ( echo ${_PKG} >> ${_CWD}/error_build_pkgs.log & continue )
                echo ${_PKG} >> ${_CWD}/install_pkgs.log
                move_pkg ${_PKG} $p
#            installpkg ${_TXZ}/$t/$p-*.txz || exit 1
                installpkg ${_TXZ}/${_PKG}/$p-*.txz || exit 1
#                installpkg ${_INSTALL}/$t/$p-*.txz || continue
                popd
#            fi
        fi
    done
}

build


