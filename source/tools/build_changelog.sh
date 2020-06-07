#!/bin/bash

LANG=C
CHANGELOG="ChangeLog.txt"
PATH_DISTRO=${PATH_DISTRO:-"/mnt/data/shares/linux/slarm64/slarm64-current"}
PREFFIX_DISTRO=${PREFFIX_DISTRO:-"slarm64"}
WORK_DIR=$(mktemp -d)
FILTER=".*\.\(tgz\|txz\)"
DELIMITER="+--------------------------+"




get_last_timestamp() {
    TIMESTAMP=$(grep 'UTC' ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null | head -n 1)
    [[ -z $TIMESTAMP ]] && TIMESTAMP=$(date -u -d '1 hour ago')
    TIMESTAMP=$(date -u --date="$TIMESTAMP" +'%F %X')
    echo $TIMESTAMP
}

mark_new_update() {
    if [[ -f ${WORK_DIR}/new ]]; then
        for pkg in $(cat ${WORK_DIR}/new); do
            __pkg=$(echo ${pkg} | rev | cut -d '-' -f2- | rev)
            _pkg=$(echo ${pkg} | rev | cut -d '-' -f4- | rev)
            if [[ $(grep -e ${__pkg} ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null) && ! $(grep -e ${pkg} ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null) ]]; then
                sed -i "s:$pkg:$pkg\:  Rebuilt\.:" ${WORK_DIR}/new
            elif [[ $(grep -e ${_pkg} ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null) && ! $(grep -e ${pkg} ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null) ]]; then
                sed -i "s:$pkg:$pkg\:  Upgraded\.:" ${WORK_DIR}/new
            elif [[ ! $(grep -e ${_pkg} ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null) ]]; then
                sed -i "s:$pkg:$pkg\:  Added\.:" ${WORK_DIR}/new
            else
                sed -i -e "s:${pkg}::g" -e "/^$/d" ${WORK_DIR}/new
            fi
        done
    fi
}

mark_remove() {
    find $PATH_DISTRO -regex $FILTER -print | rev | cut -d '-' -f4- | rev | sed -e "s:${PATH_DISTRO}\/\|${PREFFIX_DISTRO}\/::g" > ${WORK_DIR}/current
    cat "${PATH_DISTRO}/${CHANGELOG}" 2>/dev/null | grep ${FILTER} | rev | cut -d '-' -f4- | rev | sort | uniq >> ${WORK_DIR}/uniq
    for f in $(cat "${PATH_DISTRO}/${CHANGELOG}" 2>/dev/null | grep ${FILTER} | grep Removed | rev | cut -d '-' -f4- | rev); do
        sed -i -e "s:${f}$::g" -e "/^$/d" ${WORK_DIR}/uniq
    done
    for pkg in $(cat ${WORK_DIR}/uniq); do
        _pkg=$(grep -e $pkg ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null | head -n 1 | cut -d ':' -f 1)
        [[ ! $(grep -e ${pkg} ${WORK_DIR}/current) && ! -z ${_pkg} ]] && echo ${_pkg} | sed 's:$:\:  Removed\.:' >> ${WORK_DIR}/remove
    done
}

FILES=$(find $PATH_DISTRO -newermt "$(get_last_timestamp)" -regex $FILTER)

for pkg in ${FILES}; do
    echo ${pkg} | sed -e "s:${PATH_DISTRO}\/\|${PREFFIX_DISTRO}\/::g" >> ${WORK_DIR}/new
done


mark_new_update
mark_remove

if [[ -s ${WORK_DIR}/remove || -s ${WORK_DIR}/new ]]; then
    cat ${WORK_DIR}/remove ${WORK_DIR}/new 2>/dev/null | sort > ${WORK_DIR}/packages
fi

if [[ -f ${WORK_DIR}/packages ]]; then
    echo "$DELIMITER" >> ${WORK_DIR}/packages
    echo $(date -u) > ${WORK_DIR}/headers
    echo "$(cat ${WORK_DIR}/headers ${WORK_DIR}/packages ${PATH_DISTRO}/${CHANGELOG} 2>/dev/null)" > ${PATH_DISTRO}/${CHANGELOG}
fi

[[ -d $WORK_DIR ]] && rm -rf $WORK_DIR
