#!/bin/bash

_CWD=$(pwd)
THREADS=$(grep -c 'processor' /proc/cpuinfo)

_BUILD="${_CWD}/slarm64-current/source"
_TXZ="${_CWD}/slarm64-current/slarm64"
_SOURCE="${_CWD}/slackware64-current/source"
_TMP="/tmp"
_WORK_DIR="work"


environment() {
    export CPPFLAGS="-D_FORTIFY_SOURCE=2"
    export CFLAGS="-O2 -pipe -fstack-protector-strong -fno-plt"
    export CXXFLAGS="-O2 -pipe -fstack-protector-strong -fno-plt"
    export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
}

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
        [[ ! $(patch -p1 --batch --dry-run -N -i ../${pf}.patch | grep previously) ]] && ( patch -p1 --verbose -i "../${pf}.patch" || return 1 )
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

#----------------------------
# read packages
#----------------------------
read_packages() {
#    local TYPE="$1"
    local PKG
#    PKG=( $(cat $_CWD/build_packages-${TYPE}.conf | grep -v "^#") )
    PKG=( $(cat $_CWD/build_packages.conf | grep -v "^#") )
#    eval "$2=\${PKG[*]}"
    eval "$1=\${PKG[*]}"
}

build() {
    # read packages
    read_packages PACKAGES

    for _PKG in ${PACKAGES};do
        if [[ ! $(echo "${_PKG}" | grep "^#") ]];then
            ERROR=0
            # set global environment
            environment
#            echo "${_PKG}"
            t=$(echo ${_PKG} | cut -d '/' -f1)
            p=$(echo ${_PKG} | cut -d '/' -f2)

            if [[ $t == kde && -e ${_BUILD}/$t/.rules ]]; then
                source ${_BUILD}/$t/.rules
                continue
            fi

            [[ ! -d ${_BUILD}/${_PKG} ]] && ( mkdir -p ${_BUILD}/${_PKG} || return 1 )
#            if [[ ! $(ls ${_INSTALL}/$t/ | grep "$p-") ]];then
#                removepkg $p
                [[ -e ${_BUILD}/${_PKG}/.ignore ]] && continue
                remove_work_dir "${_PKG}"
                prepare_work_dir "${_PKG}"
                pushd ${_BUILD}/${_PKG} 2>&1>/dev/null

                PKG_SOURCE=$(echo ${_WORK_DIR}/${p}-*.tar.?z)
                PKG_VERSION=$(echo $PKG_SOURCE | rev | cut -f 3- -d . | cut -f 1 -d - | rev)
                [[ -e ${_BUILD}/${_PKG}/.rules ]] && source ${_BUILD}/${_PKG}/.rules
                #echo $PKG_SOURCE >> ${_CWD}/log
                #echo ${PKG_VERSION} >> ${_CWD}/log
                #exit
                #continue

                patching_files STATUS
                [[ $STATUS == 1 ]] && fix_default
                pushd ${_WORK_DIR} 2>&1>/dev/null
                ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
                [[ ${PIPESTATUS[0]} == 1 ]] && ERROR=1
                [[ ${ERROR} == 1 ]] && mv ${p}.build.log ${p}.build.log.1
                [[ ${ERROR} == 1 ]] && fix_global ${p}
                [[ ${ERROR} == 1 ]] && ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
                if [[ ${PIPESTATUS[0]} == 1 && ${ERROR} == 1 ]]; then
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


