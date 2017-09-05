config() {
  NEW="$1"
  OLD="`dirname $NEW`/`basename $NEW .new`"
  # If there's no config file by that name, mv it over:
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "`cat $OLD | md5sum`" = "`cat $NEW | md5sum`" ]; then # toss the redundant copy
    rm $NEW
  fi
  # Otherwise, we leave the .new copy for the admin to consider...
}

# Keep same perms on rc.yp.new:
if [ -e etc/rc.d/rc.yp ]; then
  cp -a etc/rc.d/rc.yp etc/rc.d/rc.yp.new.incoming
  cat etc/rc.d/rc.yp.new > etc/rc.d/rc.yp.new.incoming
  mv etc/rc.d/rc.yp.new.incoming etc/rc.d/rc.yp.new
fi

config etc/nsswitch.conf-nis.new
config etc/netgroup.new
config etc/yp.conf.new
config etc/default/yp.new
config etc/rc.d/rc.yp.new
config var/yp/nicknames.new
config var/yp/Makefile.new
config var/yp/securenets.new

# No, don't delete these.  They might have a few changes that need to be merged.
#rm -f etc/nsswitch.conf-nis.new etc/netgroup.new etc/yp.conf.new var/yp/nicknames.new var/yp/Makefile.new var/yp/securenets.new

