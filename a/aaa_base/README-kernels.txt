#######################################################################
# Document: /boot/README-kernels.txt
# Purpose:  Explain the various files
# Author:   Stuart Winter <mozes@slackware.com>
# Date:     26-Sep-2016
# Version:  1.01
#######################################################################

With a full installation of Slackware 15.0, Slackware ARM contains
a single Kernel that supports all "officially supported" devices:

   kernel_armv7-<Linux version>-arm-<build number>

These packages contain kernels for a variety of ARMv7 devices.

In the /boot directory, you will see a number of symbolic links and their
corresponding versioned file.  Here is a short run down:-

   uImage-armv7

     These are images that are specifically for the 'U-Boot' boot loader
     which is a popular boot loader used on many ARM devices.  This loader
     obtains some of its information from data baked into the 'uImage'.  This
     'uImage' file is essentially a wrapped Linux 'zImage' kernel.

     If your system does not use U-Boot, then you will not need these files.
     However, they are provided because the systems that Slackware ARM supports
     out-of-the-box use U-Boot.

   uinitrd-armv7

     These are the Initial RAM disks that contain the drivers (Kernel
     modules) required to boot the system.  Again, these are versions that
     are wrapped up specifically for the U-Boot boot loader.
     
   initrd-armv7

     These are the Initial RAM disks that contain the drivers (Kernel
     modules) required to boot the system.  They are the same as the "uinitrd"
     versions but only compressed with gzip.

   zImage-armv7

     These are virgin Linux kernels - no modifications.
     The purpose of these is that should your system be able to make use
     of one of the standard Slackware ARM kernels but need to modify
     or supply the original unmodified version of the Kernel, you can
     do so easily.

     Most versions of U-Boot for ARMv7 now support the standard zImage
     and "initrd" formats -- but both are supplied because the Trimslice's
     (a supported device) version of U-Boot does not.


   dtb/*

     These are the Device Tree Blob files that are used to describe
     the ARM system that you are booting.  

     All officially supported devices make use of DTB.

If you have any questions or need help, please register and post
your question at the officially supported Slackware ARM forum:
  http://www.linuxquestions.org/questions/slackware-arm-108/

-- 
Stuart Winter

