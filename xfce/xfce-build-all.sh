#!/bin/sh

# Copyright 2012, 2015  Patrick J. Volkerding, Sebeka, Minnesota, USA
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# Include the Slackware ARM environment build kit:
source /usr/share/slackdev/buildkit.sh

# Set to 1 if you'd like to install/upgrade package as they are built.
# This is recommended.
INST=1

for (( pass=1; pass <4 ; pass++ )); do
  echo "**********************"
  echo "***** PASS $pass *****"
  echo "**********************"

   # We'll care about the output of the last pass only:
   rm -f /tmp/xfce-output.log

   for package in \
     xfce4-dev-tools \
     libxfce4util \
     xfconf \
     libxfce4ui \
     exo \
     garcon \
     tumbler \
     Thunar \
     xfce4-panel \
     xfce4-settings \
     xfce4-session \
     xfdesktop \
     xfwm4 \
     xfce4-appfinder \
     gtk-xfce-engine \
     xfce4-terminal \
     orage \
     thunar-volman \
     xfce4-power-manager \
     xfce4-pulseaudio-plugin \
     xfce4-notifyd \
     xfce4-clipman-plugin \
     xfce4-screenshooter \
     xfce4-systemload-plugin \
     xfce4-taskmanager \
     xfce4-weather-plugin \
     ; do
     cd $package || exit 1
     rm -f /tmp/${package}.failed # only care about the last pass
     dbuild || ( touch /tmp/${package}.failed ; exit 1 ) || exit 1
     if [ -f $PKGSTORE/xfce/$package-*t?z ]; then
        ui $PKGSTORE/xfce/$package-*t?z
      else
        echo "** No package file found for $package!!***" >> /tmp/xfce-output.log
     fi
     cd ..
   done
done

# Dump any package installation errors:
if [ -s /tmp/xfce-output.log ]; then
   cat /tmp/xfce-output.log
fi
