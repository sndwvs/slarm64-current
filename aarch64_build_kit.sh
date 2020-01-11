#!/bin/bash

BCWD=$(pwd)
THREADS=$(grep -c 'processor' /proc/cpuinfo)

DISTR="slarm64"
SLACKWARE_PATH="${BCWD}/slackware64-current"
SLARM64_PATH="${BCWD}/slarm64-current"
PREFIX_SOURCE=${PREFIX_SOURCE:-"source"}
BTMP="/tmp"
WORK_DIR="work"


environment() {
    [[ -z "$1" ]] && return 1
    local TYPE="$1"
    local PACKAGE="$2"

    export LANG=C
    export CPPFLAGS="-D_FORTIFY_SOURCE=2"
    export CFLAGS="-O2 -pipe -fstack-protector-strong -fno-plt"
    export CXXFLAGS="-O2 -pipe -fstack-protector-strong -fno-plt"
    export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

    if [[ ${TYPE} == "extra" ]]; then
        export SLACKWARE_SOURCE_PATH="${SLACKWARE_PATH}/${TYPE}/${PREFIX_SOURCE}"
#        export PACKAGES_PATH="${SLARM64_PATH}/${TYPE}/${PACKAGE}"
        export PACKAGES_PATH="${SLARM64_PATH}"
        export SLARM64_SOURCE_PATH="${SLARM64_PATH}/${TYPE}/${PREFIX_SOURCE}"
    else
        export SLACKWARE_SOURCE_PATH="${SLACKWARE_PATH}/${PREFIX_SOURCE}"
        export PACKAGES_PATH="${SLARM64_PATH}/${DISTR}"
        export SLARM64_SOURCE_PATH="${SLARM64_PATH}/${PREFIX_SOURCE}"
    fi
}

remove_work_dir() {
    [[ ! -z "$1" ]] && rm -rf "${SLARM64_SOURCE_PATH}/$1/${WORK_DIR}"
}

prepare_work_dir() {
    [[ -z "$1" ]] && return 1
    [[ ! -d "${SLARM64_SOURCE_PATH}/$1/${WORK_DIR}" ]] && mkdir "${SLARM64_SOURCE_PATH}/$1/${WORK_DIR}"

    # if new packages copy all
    if [[ -e ${SLARM64_SOURCE_PATH}/$1/.new ]]; then
        pushd ${SLARM64_SOURCE_PATH}/$1/ 2>&1>/dev/null
        cp -a $(ls | grep -vP '^work$') ${SLARM64_SOURCE_PATH}/$1/${WORK_DIR}/
        popd 2>&1>/dev/null
        return 1
    fi

    for f in $(ls "${SLACKWARE_SOURCE_PATH}/$1/");do
        if [[ ! -L $f ]];then
            cp -a "${SLACKWARE_SOURCE_PATH}/$1/$f" ${SLARM64_SOURCE_PATH}/$1/${WORK_DIR}/$(basename $f)
        else
            ln -s "${SLACKWARE_SOURCE_PATH}/$1/$f" "${SLARM64_SOURCE_PATH}/$1/${WORK_DIR}/$(basename $f)"
        fi
    done
    [[ $(ls ${SLARM64_SOURCE_PATH}/$1/ | grep .xz) ]] && cp -a ${SLARM64_SOURCE_PATH}/$1/*.xz \
                                                  ${SLARM64_SOURCE_PATH}/$1/${WORK_DIR}/
}

fix_default() {
    for pf in $(find ${WORK_DIR}/ -maxdepth 1 -type f | grep .SlackBuild);do
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
esac\n/};p' -i "${WORK_DIR}/${pf}"
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
        pushd ${WORK_DIR} 2>&1>/dev/null
        [[ ! $(patch -p1 --batch --dry-run -N -i ../${pf}.patch | grep "previously\|already exists") ]] && ( patch -p1 --verbose -i "../${pf}.patch" || return 1 )
        popd 2>&1>/dev/null
        count=$(($count+1))
    done
    eval "$1=\$count"
}

move_pkg() {
    [[ -z "$1" ]] && exit 1
    [[ ! -d "${PACKAGES_PATH}/$1" ]] && ( mkdir -p "${PACKAGES_PATH}/$1" || return 1 )
    if [[ -e "${PACKAGES_PATH}/$1" ]]; then
        for pkg in $(ls ${BTMP}/$2-*.t?z); do
            if [[ ${pkg} =~ "-solibs-" ]];then
                local SERIES="a"
                #[[ ${pkg} =~ "seamonkey-solibs-" ]] && SERIES="l"
                mv ${pkg} "${PACKAGES_PATH}/${SERIES}/"
            else
                mv ${pkg} "${PACKAGES_PATH}/$1/"
            fi
        done
    fi
}

#----------------------------
# read packages
#----------------------------
read_packages() {
    local PKG
    PKG=( $(cat $BCWD/build_packages.conf | grep -v "^#") )
    eval "$1=\${PKG[*]}"
}

build() {
    # read packages
    read_packages PACKAGES

    for _PKG in ${PACKAGES};do
        if [[ ! $(echo "${_PKG}" | grep "^#") ]];then
            ERROR=0

#            echo "${_PKG}"
            t=$(echo ${_PKG} | cut -d '/' -f1)
            p=$(echo ${_PKG} | cut -d '/' -f2)

            # set global environment
            environment "$t" "$p"

            # build extra series
            [[ ${t} == "extra" ]] && _PKG=${_PKG/$t\///}

            # build kernel series
            if [[ $t == k && -e ${SLARM64_SOURCE_PATH}/$t/.rules ]]; then
                source ${SLARM64_SOURCE_PATH}/$t/.rules
                continue
            fi

            # build kde series
            if [[ $t == kde && -e ${SLARM64_SOURCE_PATH}/$t/.rules ]]; then
                source ${SLARM64_SOURCE_PATH}/$t/.rules
                continue
            fi

            # build x11 series
            if [[ $t == x ]]; then
                X11_PKG_PATH=$(find ${SLACKWARE_SOURCE_PATH}/$t/ -type f -name "${p}-*.?z")
                X11_MODULE=$(echo ${X11_PKG_PATH} | rev | cut -d '/' -f2 | rev)
                if [[ ! -z $X11_MODULE && ${X11_PKG_PATH} =~ '/x11/' ]]; then
                    x11_root="x11"
                    source ${SLARM64_SOURCE_PATH}/$t/$x11_root/.rules
                    unset X11_PKG_PATH X11_MODULE
                    continue
                fi
            fi

            [[ ! -d ${SLARM64_SOURCE_PATH}/${_PKG} ]] && ( mkdir -p ${SLARM64_SOURCE_PATH}/${_PKG} || return 1 )
            [[ -e ${SLARM64_SOURCE_PATH}/${_PKG}/.ignore ]] && continue
            remove_work_dir "${_PKG}"
            prepare_work_dir "${_PKG}"
            pushd ${SLARM64_SOURCE_PATH}/${_PKG} 2>&1>/dev/null

            PKG_SOURCE=$(echo ${WORK_DIR}/${p}-*.tar.?z)
            PKG_VERSION=$(echo $PKG_SOURCE | rev | cut -f 3- -d . | cut -f 1 -d - | rev)

            [[ -e ${SLARM64_SOURCE_PATH}/${_PKG}/.rules ]] && source ${SLARM64_SOURCE_PATH}/${_PKG}/.rules

            # build extra/aspell-word-lists series
            [[ ${t} =~ "extra" && ${p} == "aspell-word-lists" ]] && continue

            #echo $PKG_SOURCE >> ${BCWD}/log
            #echo ${PKG_VERSION} >> ${BCWD}/log
            #exit
            #continue

            patching_files STATUS
            [[ $STATUS == 1 ]] && fix_default
            pushd ${WORK_DIR} 2>&1>/dev/null
            ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
            [[ ${PIPESTATUS[0]} == 1 ]] && ERROR=1
            [[ ${ERROR} == 1 ]] && mv ${p}.build.log ${p}.build.log.1
            [[ ${ERROR} == 1 ]] && fix_global ${p}
            [[ ${ERROR} == 1 ]] && ./${p}.SlackBuild 2>&1 | tee ${p}.build.log
            if [[ ${PIPESTATUS[0]} == 1 && ${ERROR} == 1 ]]; then
                [[ ${t} == "extra" ]] && _PKG="${t}${_PKG}"
                echo "${_PKG}" 2>&1 >> ${BCWD}/build_error.log
                continue
            fi
            popd 2>&1>/dev/null
            [[ ${t} == "extra" ]] && t="${t}/${p}"
            move_pkg ${t} ${p}
            upgradepkg --install-new --reinstall ${PACKAGES_PATH}/${t}/${p}-*.txz
            popd 2>&1>/dev/null
        fi
    done
}

build


