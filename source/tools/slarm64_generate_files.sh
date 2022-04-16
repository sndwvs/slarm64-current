#!/bin/bash

export LANG=C

DISTR=${DISTR:-slarm64}
DISTR_ROOT=${DISTR_ROOT:-/mnt/data/shares/linux/slackware/${DISTR}-15.0/}
DISTR_OWNER=${DISTR_OWNER:-$DISTR}
FILELIST=${FILELIST:-FILE_LIST}
PACKAGES="PACKAGES.TXT"
CHECKSUMS="CHECKSUMS.md5"
MANIFEST="MANIFEST"
EXCLUDES=".git .gitignore"
COMPRES="xz"
GPG="gpg2"
TMP_PKGS=$(mktemp)


PRUNES=""
for substr in $EXCLUDES ; do
    PRUNES="${PRUNES} -name ${substr} -prune -o -true"
done

read -ers -p "Enter your GPG passphrase: "
echo -e ""
GPG_PASS=$REPLY
REPLY=""

if [[ ! -e ${DISTR_ROOT}GPG-KEY ]]; then
  echo "create a \"GPG-KEY\" file in '$DISTR_ROOT',"
  echo "add information about the public key for '$DISTR_OWNER'."
  $GPG --list-keys "$DISTR_OWNER" > ${DISTR_ROOT}GPG-KEY
  $GPG -a --export "$DISTR_OWNER" >> ${DISTR_ROOT}GPG-KEY
  chmod 444 ${DISTR_ROOT}GPG-KEY
fi




### gen_data
get_data() {
  local _DATE=$(LANG=C date -u)
  eval "$1=\${_DATE}"
}


### get files from a directory
get_files() {
    local DIR="$1"
    find -L ${DIR} $PRUNES -type f -name '*.t?z' -print | sort -t'/' -k3 > $TMP_PKGS
}


### gen_gpg
gen_gpg() {
  # Argument #1 : full path to a package
  local PKG="$1"
  local ASCFILE="${PKG}.asc"

  [[ -e "${ASCFILE}" ]] && rm -f "${ASCFILE}"

  #$GPG --use-agent -bas -u "$DISTR_OWNER" --batch --quiet "${PKG}"
  echo "${GPG_PASS}" | $GPG --pinentry-mode loopback -bas -u "$DISTR_OWNER" --passphrase-fd 0 --batch --quiet "${PKG}"

  return $?
}


### gen_manifest
gen_manifest() {
  # Argument #1 : full path to a package
  # Argument #2 : short path and name to a package
  local PKG="$1"
  local NAME="$2"

  cat <<EOT >> ${MANIFEST}
++========================================
||
||   Package:  ${NAME}
||
++========================================
EOT

  $COMPRES -dc ${PKG} | tar -tvvf - >> ${MANIFEST}
  echo -e "\n" >> ${MANIFEST}
}


### gen_file_packages
gen_file_packages() {
  # Argument #1 : full path to a directory
  local DIR="$1"
  local _DIR=$(basename $DIR)

  pushd ${DIR} 2>&1>/dev/null

  # shrink file
  > ${PACKAGES} > ${MANIFEST}

  get_data UPDATE_DATE

  get_files ${DIR}

  while IFS= read -r line; do
    PKG=${line}
    NAME=${line##*/}
    LOCATION=${line/${DISTR_ROOT}/./}
    LOCATION=${LOCATION%/*}

    SIZE=$(du -s $PKG | cut -f 1)
    USIZE=$($COMPRES --robot --list $PKG | awk '/^totals/{printf("%i"), $5/1024}')

    cat <<EOT >> ${PACKAGES}

PACKAGE NAME:  $NAME
PACKAGE LOCATION:  $LOCATION
PACKAGE SIZE (compressed):  $SIZE K
PACKAGE SIZE (uncompressed):  $USIZE K
PACKAGE DESCRIPTION:
EOT

    $COMPRES -dc ${PKG} | tar xOf - install/slack-desc | sed -n '/^#/d;/:/p' >> ${PACKAGES}

     # manifest creation
     gen_manifest $PKG ${line/${DIR}/.}
     # gpg creation
     gen_gpg $PKG
  done < "$TMP_PKGS"

  SIZE=$(grep '(compressed):' ${PACKAGES} | awk '{SUM += $4} END {printf("%i"), SUM/1024}')
  USIZE=$(grep '(uncompressed):' ${PACKAGES} | awk '{SUM += $4} END {printf("%i"), SUM/1024}')

  read -r -d '' HEAD << EOT
$PACKAGES;  $UPDATE_DATE

This file provides details on the $DISTR packages found
in the ./${_DIR}/ directory.

Total size of all packages (compressed):  $SIZE MB
Total size of all packages (uncompressed):  $USIZE MB
EOT

  awk -i inplace -v p="\n$HEAD\n" 'BEGINFILE{print p}{print}' ${PACKAGES}

  # manifest compression
  [[ -e ${MANIFEST} ]] && rm -f ${MANIFEST}.bz2 && bzip2 ${MANIFEST}

  popd 2>&1>/dev/null
}


### gen_filelist
gen_filelist() {
  # Argument #1 : full path to a directory
  # Argument #2 : output filename

  local DIR="$1"
  local LISTFILE="$2"

  get_data UPDATE_DATE

  pushd ${DIR} 2>&1>/dev/null

  # shrink file
  > ${LISTFILE}

  cat <<EOT > ${LISTFILE}
${UPDATE_DATE}

Here is the file list for this directory.  If you are using a 
mirror site and find missing or extra files in the disk 
subdirectories, please have the archive administrator refresh
the mirror.

EOT

  find -L . ${PRUNES} -print | sort | xargs ls -ld --time-style=long-iso >> ${LISTFILE}

  popd 2>&1>/dev/null
}


### gen_file_checksums
gen_file_checksums() {
  # Argument #1 : full path to a directory

  local DIR=$1

  pushd $DIR 2>&1>/dev/null

  # shrink file
  > $CHECKSUMS

  cat <<EOT >> ${CHECKSUMS}
These are the MD5 message digests for the files in this directory.
If you want to test your files, use 'md5sum' and compare the values to
the ones listed here.

To test all these files, use this command:

tail +13 CHECKSUMS.md5 | md5sum -c --quiet - | less

'md5sum' can be found in the GNU coreutils package on ftp.gnu.org in
/pub/gnu, or at any GNU mirror site.

MD5 message digest                Filename
EOT

  find -L . $PRUNES -type f -print | sort | xargs md5sum >> ${CHECKSUMS}

  # gpg creation
  gen_gpg ${CHECKSUMS}

  popd 2>&1>/dev/null
}




### main program
for DIR in $DISTR_ROOT*;do
  if [[ -d ${DIR} ]]; then
    echo "generate for $(basename ${DIR})"
    [[ ! $(basename $DIR) =~ 'source' ]] && gen_file_packages ${DIR}
    if [[ $(basename $DIR) =~ ${DISTR} ]]; then
        cp ${DIR}/${PACKAGES} ${DISTR_ROOT}${PACKAGES}
        ln -sf ${DISTR_ROOT}${PACKAGES} -r ${DIR}/${PACKAGES}
    fi
    gen_filelist ${DIR} $FILELIST
    gen_file_checksums ${DIR}
  fi
done

# base distro directory
gen_filelist ${DISTR_ROOT} "FILELIST.TXT"
gen_file_checksums ${DISTR_ROOT}

# clean
GPG_PASS=""
