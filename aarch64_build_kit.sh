#!/bin/bash

_CWD=$(pwd)
THREADS=$(($(grep -c 'processor' /proc/cpuinfo)-2))

#source config.sh || exit 1
#source "packages-minirootfs.conf" || exit 1
#source "l-packages.conf" || exit 1
#source "tcl-packages.conf" || exit 1
#source "d-packages.conf" || exit 1
#source "ap-packages.conf" || exit 1
#source "a-packages.conf_" || exit 1
#source "l.conf" || exit 1
source "n-packages.conf" || exit 1


_BUILD="${_CWD}/slackwarearm64-current/source"
_TXZ="${_CWD}/slackwarearm64-current/slackware"
_SOURCE="${_CWD}/slackware64-current/source"
_TMP="/tmp"
_WORK_DIR="work"


remove_work_dir() {
    [[ ! -z "$1" ]] && rm -rf "${_BUILD}/$1/${_WORK_DIR}"
}

prepare_work_dir() {
    [[ -z "$1" ]] && return 1
    [[ ! -d "${_BUILD}/$1/${_WORK_DIR}" ]] && mkdir "${_BUILD}/$1/${_WORK_DIR}"
    for f in $(ls "${_SOURCE}/$1/");do
        if [[ ! -L $f ]];then
            cp -a "${_SOURCE}/$1/$f" ${_BUILD}/$1/${_WORK_DIR}/$(basename $f)
        else
            ln -s "${_SOURCE}/$1/$f" "${_BUILD}/$1/${_WORK_DIR}/$(basename $f)"
        fi
    done
}

fix_default() {
    for pf in $(find ${_WORK_DIR}/ -maxdepth 1 -type f | grep .SlackBuild);do
        pf=$(basename "$pf")
        echo "$pf"
        sed -n '/if \[ \"$ARCH\" = \"\(i.86\)\" \]/{:a;N;/fi$/!ba;N;s/.*\n/case \"\$ARCH\" in\
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
esac\n/};p' -i "${_WORK_DIR}/${pf}"
    done
}

fix_global() {
  [[ -z "$1" ]] && return 1
  sed -e "s/\" -j. \"/\" -j$THREADS \"/" \
      -e 's/\(-slackware\)\(-linux.*\s\)/-unknown\2/g' \
      -e 's/\(-slackware\)\(-linux$\)/-unknown\2/g' \
      -i ${_WORK_DIR}/${1}.SlackBuild
}

patching_files() {
    local PATCH_FILES=$(find -maxdepth 1 -type f | grep patch | sed 's#.patch$##')
    local count=1
    for pf in "${PATCH_FILES}";do
        pf=$(basename "$pf")
        [[ -z "$pf" ]] && continue
        pushd ${_WORK_DIR} 2>&1>/dev/null
        patch -p1 --verbose < "../${pf}.patch" || return 1
        popd 2>&1>/dev/null
        count=$(($count+1))
    done
    eval "$1=\$count"
}

move_pkg() {
    [[ -z "$1" ]] && exit 1
    [[ ! -d "${_TXZ}/$1" ]] && ( mkdir -p "${_TXZ}/$1" || return 1 )
    [[ -e "${_TXZ}/$1" ]] && mv ${_TMP}/$2-*.txz "${_TXZ}/$1/"
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
                remove_work_dir "${_PKG}"
                prepare_work_dir "${_PKG}"
                pushd ${_BUILD}/${_PKG} 2>&1>/dev/null
                [[ -e .ignore ]] && continue
                patching_files STATUS
                [[ $STATUS == 1 ]] && fix_default
#                fix_global ${p}
                pushd ${_WORK_DIR} 2>&1>/dev/null
                ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
                if [[ ${PIPESTATUS[0]} == 1 ]];then
                    echo "${_PKG}" 2>&1 >> ${_CWD}/build_error.log
                    continue
                fi
                popd 2>&1>/dev/null
                move_pkg ${t} ${p}
                installpkg ${_TXZ}/${t}/${p}-*.txz
                popd 2>&1>/dev/null
#            fi
        fi
    done
}

build


