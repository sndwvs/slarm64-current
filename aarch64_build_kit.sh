#!/bin/bash

_CWD=$(pwd)
THREADS=$(($(grep -c 'processor' /proc/cpuinfo)-2))

#source config.sh || exit 1
#source "packages-minirootfs.conf" || exit 1
#source "n-packages.conf_" || exit 1
#source "l-packages.conf" || exit 1
#source "tcl-packages.conf" || exit 1
#source "d-packages.conf" || exit 1
#source "ap-packages.conf_" || exit 1
source "a-packages.conf_" || exit 1
#source "l.conf" || exit 1

_BUILD="${_CWD}/slackwarearm64-current/source"
_TXZ="${_CWD}/slackwarearm64-current/slackware"
_SOURCE="${_CWD}/slackware64-current/source"


remove_links() {
    [[ -z "$1" ]] && return 1
    find "${_BUILD}/$1/" -type l -delete
}

create_links() {
    [[ -z "$1" ]] && return 1
    ln -sf "${_SOURCE}/$1/"* "${_BUILD}/$1/"
}

fix_default() {
    [[ -z "$1" ]] && return 1
    local PATCH_FILES=$(find -type l | grep .SlackBuild)
    for pf in "${PATCH_FILES}";do
        pf=$(basename "$pf")
        echo "$pf"
        rm "$pf"
        cp -af "${_SOURCE}/$1/${pf}" "${_BUILD}/$1/"
        sed -n '/if \[ \"$ARCH\" = \"\(i.86\|x86_64\)\" \]/{:a;N;/fi$/!ba;N;s/.*\n/case \"\$ARCH\" in\
     i?86\) SLKCFLAGS=\"-O2 -march=i586 -mtune=i686\"\
           LIBDIRSUFFIX=\"\"\
           ;;\
   x86_64\) SLKCFLAGS=\"-O2 -fPIC\"\
           LIBDIRSUFFIX=\"64\"\
           ;;\
  aarch64\) SLKCFLAGS=\"-O2\"\
           LIBDIRSUFFIX=\"64\"\
           ;;\
        \*\) SLKCFLAGS=\"-O2\"\
           LIBDIRSUFFIX=\"\"\
           ;;\
esac\n/};p' -i "${pf}"
    done
}

fix_global() {
  [[ -z "$1" ]] && return 1
  sed -e "s/\" -j. \"/\" -j$THREADS \"/" \
      -e 's/\(-slackware\)\(-linux.*\s\)/-unknown\2/g' \
      -e 's/\(-slackware\)\(-linux$\)/-unknown\2/g' \
      -i ${1}.SlackBuild
}

patching_files() {
    [[ -z "$1" ]] && return 1
    local PATCH_FILES=$(find -type f | grep patch | sed 's#.patch$##')
    local count=1
    for pf in "${PATCH_FILES}";do
        pf=$(basename "$pf")
        [[ -z "$pf" ]] && continue
        echo "$pf"
        rm "$pf"
        cp -a "${_SOURCE}/$1/${pf}" "${_BUILD}/$1/"
        patch -p1 --verbose < "${pf}.patch" || return 1
        count=$(($count+1))
    done
    eval "$2=\$count"
}

move_pkg() {
    [[ -z "$1" ]] && exit 1
    [[ ! -d "${_TXZ}/$1" ]] && ( mkdir -p "${_TXZ}/$1" || return 1 )
    [[ -e "${_TXZ}/$1" ]] && mv /tmp/$2-*.txz "${_TXZ}/$1/"
}

build() {
    for _PKG in $PKG_LIST;do
        if [[ ! $(echo "${_PKG}" | grep "^#") ]];then
#            echo "${_PKG}"
            [[ ! -d ${_BUILD}/${_PKG} ]] && ( mkdir -p ${_BUILD}/${_PKG} || return 1 )
            t=$(echo ${_PKG} | cut -d '/' -f1)
            p=$(echo ${_PKG} | cut -d '/' -f2)
#            if [[ ! $(ls ${_INSTALL}/$t/ | grep "$p-") ]];then
#                removepkg $p
                remove_links "${_PKG}"
                create_links "${_PKG}"
                pushd ${_BUILD}/${_PKG}/ 2>&1>/dev/null
                [[ -e .ignore ]] && continue
                patching_files ${_PKG} STATUS
                [[ $STATUS == 1 ]] && fix_default ${_PKG}
                fix_global ${p}
                ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
                if [[ ${PIPESTATUS[0]} == 1 ]];then
                    echo "${_PKG}" 2>&1 >> ${_CWD}/build_error.log
                    continue
                fi
                move_pkg ${t} ${p}
                installpkg ${_TXZ}/${t}/${p}-*.txz
                popd 2>&1>/dev/null
#            fi
        fi
    done
}

build


