
# If we're on an Acorn StrongARM RiscPC (or any Acorn machine, but
# ARMedslack only supports the StrongARM RiscPC) then we need the RiscPC keymaps
# rather than the normal versions.
# Can you think of a better way of doing this? mozes@slackware.com would
# like to know.
#
# 22-Jan-05:
#  - Linux 2.6 knows about RiscPC keyboards and since ARMedslack now uses Linux 2.6
#    as its standard Kernel, we no longer need these keymaps.
#    However, as it doesn't hurt to have them around *and* they are required for Linux 2.4
#    and earlier, we'll just leave them.
#    During boot, I *could* modify the rc scripts to recognise the Kernel version and
#    load the corresponding keymaps accordingly, but the Linux 2.4 Kernel for RiscPC
#    is pretty broken in many respects and I'd really people rather not use it.
#    If a broken keymap deters them, then that's great! ;-)
#
#( cd usr/share/kbd
#  rm -f keymaps
#  ( grep 'Acorn-RiscPC' /proc/cpuinfo ) > /dev/null 2>&1
#  # We're on a RiscPC
#  if [ $? -eq 0 ]; then
#     ln -fs keymaps-acorn-for-linux-2.4 keymaps
#   else
#     # Not on an Acorn, so let's use the real keymaps:
#     ln -fs keymaps-original keymaps
#  fi
#)
