#!/bin/bash

_CWD=$(pwd)
THREADS=$(($(grep -c 'processor' /proc/cpuinfo)-2))

#source config.sh || exit 1
#source "packages-minirootfs.conf" || exit 1
#source "l-packages.conf" || exit 1
#source "tcl-packages.conf" || exit 1
#source "d-packages.conf" || exit 1
#source "ap-packages.conf" || exit 1
##source "a-packages.conf" || exit 1
#source "l.conf" || exit 1
source "pkg" || exit 1
#source "xap.conf" || exit 1
#source "xfce.conf" || exit 1
#source "n-packages.conf" || exit 1
#source "x-packages.conf" || exit 1


_BUILD="${_CWD}/slarm64-current/source"
_TXZ="${_CWD}/slarm64-current/slackware"
_SOURCE="${_CWD}/slackware64-current/source"
_TMP="/tmp"
_WORK_DIR="work"


remove_work_dir() {
    [[ ! -z "$1" ]] && rm -rf "${_BUILD}/$1/${_WORK_DIR}"
}

prepare_work_dir() {
    [[ -z "$1" ]] && return 1
    [[ ! -d "${_BUILD}/$1/${_WORK_DIR}" ]] && mkdir "${_BUILD}/$1/${_WORK_DIR}"

    # if new packages copy all
    if [[ -e ${_BUILD}/$1/.new ]]; then
        pushd ${_BUILD}/$1/ 2>&1>/dev/null
        cp -a $(ls | grep -vP '^work$') ${_BUILD}/$1/${_WORK_DIR}/
        popd 2>&1>/dev/null
        return 1
    fi

    for f in $(ls "${_SOURCE}/$1/");do
        if [[ ! -L $f ]];then
            cp -a "${_SOURCE}/$1/$f" ${_BUILD}/$1/${_WORK_DIR}/$(basename $f)
        else
            ln -s "${_SOURCE}/$1/$f" "${_BUILD}/$1/${_WORK_DIR}/$(basename $f)"
        fi
    done
    [[ $(ls ${_BUILD}/$1/ | grep .xz) ]] && cp -a ${_BUILD}/$1/*.xz \
                                                  ${_BUILD}/$1/${_WORK_DIR}/
}

fix_default() {
    for pf in $(find ${_WORK_DIR}/ -maxdepth 1 -type f | grep .SlackBuild);do
        pf=$(basename "$pf")
        echo "$pf"
        sed -n '/^if \[ \"$ARCH\" = \"\(i.86\)\" \]/{:a;N;/fi$/!ba;N;s/.*\n/case \"\$ARCH\" in\
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
      -i ${1}.SlackBuild
}

patching_files() {
    local PATCH_FILES=$(find -maxdepth 1 -type f | grep patch$ | sed 's#.patch##')
    local count=1
    for pf in ${PATCH_FILES};do
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
                [[ -e ${_BUILD}/${_PKG}/.ignore ]] && continue
                remove_work_dir "${_PKG}"
                prepare_work_dir "${_PKG}"
                pushd ${_BUILD}/${_PKG} 2>&1>/dev/null
                patching_files STATUS
                [[ $STATUS == 1 ]] && fix_default
                pushd ${_WORK_DIR} 2>&1>/dev/null
                ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
                [[ ${PIPESTATUS[0]} == 1 ]] && fix_global ${p}
                ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
                if [[ ${PIPESTATUS[0]} == 1 ]];then
                    echo "${_PKG}" 2>&1 >> ${_CWD}/build_error.log
                    continue
                fi
                popd 2>&1>/dev/null
                move_pkg ${t} ${p}
                upgradepkg --install-new --reinstall ${_TXZ}/${t}/${p}-*.txz
                popd 2>&1>/dev/null
#            fi
        fi
    done
}

build

