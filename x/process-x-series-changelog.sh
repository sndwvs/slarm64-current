# Take the Slackware x86 ChangeLog entries and produce a build script for
# ARM, and figure out whether the package is just part of the "x" series or
# is part of the X.org/x11 package set.
#
# Stuart Winter <mozes@slackware.com>
# 2-Feb-2011
##################################################################################################
# Process:
#  - Add all of the new ChangeLog entries to slackwarearm-current/ChangeLog.txt, prefixed with +
#    (this is from the output of a diff between the old vs new ChangeLog)
# - Run this script!
##################################################################################################

source /usr/share/slackdev/buildkit.sh
export CWD=$SLACKSOURCE/x
CHANGELOG=~/ac/ChangeLog.txt

rm -f /tmp/x*-new-*

# Return a package name that has been stripped of the dirname portion
# and any of the valid extensions (only):
pkgbase() {
  # basename + strip extensions .tbz, .tgz, .tlz and .txz
  echo "$1" | sed 's?.*/??;s/\.t[bglx]z$//'
}

# Strip version, architecture and build from the end of the name
package_name() {
  pkgbase $1 | sed 's?-[^-]*-[^-]*-[^-]*$??'
}

( egrep "^\+x/.*t[bglx]z:" $CHANGELOG | sed 's?^+??g'| cut -d/ -f2 | while read line ; do
    pkg=$( package_name $( echo $line | awk -F: '{print $1}' ) )
    echo $line | grep -q "Upgraded" && tag=Upgraded
    echo $line | grep -q "Added" && tag=Added
    echo $line | grep -q "Rebuilt" && tag=Rebuilt
    # Check if it's in the Slackware x86 master tree's "slackware/x/" directory:
    if [ -d $CWD/$pkg ]; then
       # It's in Slackware's X series but not part of X.org:
       echo $pkg >> /tmp/x-new-$tag
      else
       # It's part of X.org - one of the modular packages.
       echo " \"${pkg} ${tag:0:1}\" \\" >> /tmp/x11-new-$tag
    fi
  done )

cat << EOF

The normal build logic is to:
 - Update the 'Upgraded' packages first
 - Build the 'Added' packages
 - Rebuild the 'Rebuilt' packages

===========================================
Slackware X series packages (not x11/X.org)
===========================================

Added
-----
$( [ -s /tmp/x-new-Added ] && sort /tmp/x-new-Added | uniq )

Upgraded
--------
$( [ -s /tmp/x-new-Upgraded ] && sort /tmp/x-new-Upgraded | uniq )

Rebuilt
-------
$( [ -s /tmp/x-new-Rebuilt ] && sort /tmp/x-new-Rebuilt | uniq )


=============================================================================
Slackware X11/X.org series packages
All merged - place output into the indibuild script and it'll take care of it
locally or through r2b.
==============================================================================

$( [ -s /tmp/x11-new-Added ] && grep -v xorg-server- /tmp/x11-new-Added | sort | uniq )
$( [ -s /tmp/x11-new-Upgraded ] && grep -v xorg-server- /tmp/x11-new-Upgraded | sort | uniq )
$( [ -s /tmp/x11-new-Rebuilt ] && grep -v xorg-server- /tmp/x11-new-Rebuilt | sort | uniq )

EOF
# The "xorg-server" package build will build all of the other xorg-server-* packages.

#rm -f /tmp/x*-new-*
