#
# spec file for package clisp
#
# Copyright (c) 2017 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


# minimum suse version where the full featured package builds
%define uuid    9c43d428

Name:           clisp
Version:        2.49.60+
Release:        101.1
Summary:        A Common Lisp Interpreter
License:        GPL-2.0+
Group:          Development/Languages/Other
Url:            http://clisp.cons.org

#Source:        http://downloads.sf.net/clisp/%name-%version.tar.bz2
Source:         %name-%uuid.tar.bz2
Source3:        clisp-rpmlintrc
Source4:        README.SuSE
# PATCH-EXTEND-OPENSUSE Set the process execution domain
Patch1:         clisp-2.49-personality.patch
# PATCH-FIX-OPENSUSE Fix crash on Ia64
Patch2:         clisp-2.39-ia64-wooh.dif
# PATCH-EXTEND-OPENSUSE Help (new) CLX to work out of the box
Patch3:         clisp-2.39-clx.dif
# PATCH-EXTEND-OPENSUSE Make sure to be able to use MYCLFAGS
Patch4:         clisp-2.49-configure.dif
# PATCH-FIX-OPENSUSE Make sure to use initialized token on garbage collection
Patch5:         clisp-2.49-gctoken.dif
# PATCH-FEATURE-OPENSUSE Make CLX demos usable at runtime
Patch6:         clisp-2.49-clx_demos.dif
# PATCH-EXTEND-OPENSUSE Enable postgresql SSL feature
Patch7:         clisp-2.49-postgresql.dif
# PATCH-FIX-OPENSUSE Do not use rpath but rpath-link
Patch8:         clisp-2.49-rpath.dif
# PATCH-FIX-OPENSUSE Correct path for header for System V IPC system calls
Patch12:        clisp-linux.patch
# PATCH-EXTEND-UPSTREAM Make armv7l work
Patch15:        clisp-arm.patch
Patch14:        clisp-link.dif
Patch16:        clisp-db6.diff

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%global vimdir  %{_datadir}/vim/site/after/syntax
BuildRequires:  db-devel
BuildRequires:  dbus-1-devel
BuildRequires:  fdupes
BuildRequires:  ffcall
BuildRequires:  gdbm-devel
BuildRequires:  gtk2-devel
BuildRequires:  libglade2-devel
BuildRequires:  libsigsegv-devel
BuildRequires:  net-tools
BuildRequires:  openssl-devel
BuildRequires:  pcre-devel
BuildRequires:  postgresql-devel
BuildRequires:  readline-devel
BuildRequires:  screen
BuildRequires:  vim-data
BuildRequires:  xorg-x11-devel
#
# If set to yes do not forget to add
#   gcc-c++
# to BuildRequires
#
%define debug   no
%global rlver   %(rpm -q --qf '%{VERSION}' readline-devel | sed 's/\\.//g')
Requires(pre):  vim
Requires(pre):  vim-data
Requires:       ffcall
Provides:       %{name}-devel
Suggests:       %{name}-doc

%description
Common Lisp is a high-level, all-purpose programming language. CLISP is
an implementation of Common Lisp that closely follows the book "Common
Lisp - The Language" by Guy L. Steele Jr. This package includes an
interactive programming environment with an interpreter, a compiler,
and a debugger.  Start this environment with the command 'clisp'.

%package doc
Summary:        Documentation of CLisp
Group:          Development/Languages/Other
Requires:       %{name}
%if 0%{?suse_version} >= 1120
BuildArch:      noarch
%endif

%description doc
CLISP documentation is placed in the following directories:

/usr/share/doc/packages/clisp/

/usr/share/doc/packages/clisp/doc/

As well as the conventional CLISP, this package also includes CLX, an
extension of CLISP for the X Window System. The X Window System must be
installed before running the clx command. The description of this CLX
version (new-clx) is placed in

/usr/share/doc/packages/clisp/clx/

with the file README. The subdirectory

/usr/share/doc/packages/clisp/clx/demos/

contains two nice applications.

%prep
%setup -qT -b0 -n clisp-%uuid
%patch1  -p1 -b .sel
%patch2  -p1 -b .wooh
%patch3  -p1 -b .clx
%patch4  -p1 -b .conf
%patch5  -p1 -b .gc
%patch6  -p1 -b .demos
%patch7  -p1 -b .psql
%patch8  -p1 -b .rpath
%patch12 -p1 -b .p12
%patch14 -p0 -b .p14
%patch15 -p0 -b .p15
%patch16 -p1 -b .p16

%build
#
# Overwrite stack size limit (hopefully a soft limit only)
#
ulimit -Ss unlimited || true
ulimit -Hs unlimited || true
unset LC_CTYPE
LANG=POSIX
LC_ALL=POSIX
export LANG LC_ALL
#
# Current system
#
SYSTEM=${RPM_ARCH}-suse-linux
export PATH="$PATH:."
#
# Set gcc command line but do not use CFLAGS
#
if test %debug = yes ; then
    CC="g++"
else
    CC="gcc"
fi
CC="${CC} -g ${RPM_OPT_FLAGS} -falign-functions=4 -fno-strict-aliasing -fPIC -pipe"
case "$(uname -m)" in
    i[0-9]86)
	    CC="${CC} -mieee-fp -ffloat-store"  ;;
    arm*)   CC="${CC}"				;;
    aarch64)CC="${CC}"				;;
    ppc)    CC="${CC}"				;;
    s390)   CC="${CC}"				;;
    x86_64) CC="${CC} -fno-gcse"		;;
    sparc*) CC="${CC} -mcpu=v9 -fno-gcse"	;;
    ppc64)  CC="${CC} -fno-gcse -mpowerpc64"	;;
    s390x)  CC="${CC} -fno-gcse"		;;
    ia64)   CC="${CC} -fno-gcse"		;;
    axp|alpha)
	    CC="${CC}"				;;
esac
noexec='-DKERNELVOID32A_HEAPCODES'
nommap='-DNO_MULTIMAP_SHM -DNO_MULTIMAP_FILE -DNO_SINGLEMAP -DNO_TRIVIALMAP'
safety='-DSAFETY=3 -O'
MYCFLAGS="$(getconf LFS_CFLAGS)"
if grep -q _DEFAULT_SOURCE /usr/include/features.h
then
    MYCFLAGS="${MYCFLAGS} -D_GNU_SOURCE -D_DEFAULT_SOURCE"
else
    MYCFLAGS="${MYCFLAGS} -D_GNU_SOURCE"
fi
MYCFLAGS="${MYCFLAGS} -Wno-unused -Wno-uninitialized"
port=''
case "$(uname -m)" in
    i[0-9]86)
            MYCFLAGS="${MYCFLAGS}"				;;
    arm*)   MYCFLAGS="${MYCFLAGS} ${noexec}"			;;
    aarch64)MYCFLAGS="${MYCFLAGS}"
	    port=--enable-portability				;;
    ppc)    MYCFLAGS="${MYCFLAGS} ${noexec}"			;;
    s390)   MYCFLAGS="${MYCFLAGS} ${noexec}"			;;
    x86_64) MYCFLAGS="${MYCFLAGS}"				;;
    sparc*) MYCFLAGS="${MYCFLAGS} ${nommap} ${safety}"		;;
    ppc64)  MYCFLAGS="${MYCFLAGS} ${safety} -DWIDE_HARD"
	    port=--enable-portability				;;
    ppc64le)MYCFLAGS="${MYCFLAGS} ${safety} -DWIDE_HARD"
	    port=--enable-portability				;;
    s390x)  MYCFLAGS="${MYCFLAGS} ${safety} -DWIDE_HARD"
	    port=--enable-portability				;;
    ia64)   MYCFLAGS="${MYCFLAGS} ${nommap} ${safety}"		;;
    axp|alpha)
	    MYCFLAGS="${MYCFLAGS} ${nommap}"			;;
esac
export CC
export MYCFLAGS
unset noexec nommap safety
#
# Report final architectures
#
echo $(uname -i -m -p) %_build_arch %_arch
echo | $CC $MYCFLAGS -v -E - 2>&1 | grep /cc1
#
# Environment for the case of missing terminal
#
%global _configure	screen -D -m setarch $(uname -m) -R ./configure
%global _make		screen -D -m setarch $(uname -m) -R make
SCREENDIR=$(mktemp -d ${PWD}/screen.XXXXXX) || exit 1
SCREENRC=${SCREENDIR}/clisp
export SCREENRC SCREENDIR
exec 0< /dev/null
SCREENLOG=${SCREENDIR}/log
cat > $SCREENRC<<-EOF
	deflogin off
	deflog on
	logfile $SCREENLOG
	logfile flush 1
	logtstamp off
	log on
	setsid on
	scrollback 0
	silence on
	utf8 on
	EOF
#
# Build the current system
#
if test %debug = yes ; then
    DEBUG=--with-debug
    MYCFLAGS="${MYCFLAGS} -g3 -DDEBUG_GCSAFETY"
else
    DEBUG=""
    MYCFLAGS="${MYCFLAGS}"
fi

find -name configure | xargs -r \
    sed -ri "/ac_precious_vars='build_alias\$/ {N; s/build_alias\\n//; }"
#
# The modules i18n, syscalls, regexp
# are part of the base clisp system.
#
> $SCREENLOG
tail -q -s 0.5 -f $SCREENLOG & pid=$!
%_configure build ${DEBUG}	\
    ${port+"$port"}		\
    --prefix=%{_prefix}		\
    --exec-prefix=%{_prefix}	\
    --libdir=%{_libdir}		\
    --vimdir=%{vimdir}		\
    --fsstnd=suse		\
    --with-readline		\
    --with-dynamic-modules      \
    --with-gettext		\
    --with-module=asdf		\
    --with-module=editor	\
    --with-module=dbus		\
    --with-module=queens	\
    --with-module=gdbm		\
    --with-module=gtk2		\
    --with-module=pcre		\
    --with-module=rawsock	\
    --with-module=zlib		\
    --with-module=bindings/glibc\
    --with-module=clx/new-clx	\
    --with-module=berkeley-db	\
    --with-module=postgresql

%_make -C build
%_make -C build check

#
# Stop tail
#
sleep 1
kill $pid

#
# Check for errors
#

check=no
for err in build/tests/*.erg
do
    test -e "$err" || break
    check=yes
    cat $err
done
if test $check != no
then
    type -p uname   > /dev/null 2>&1 && uname -a || :
    type -p netstat > /dev/null 2>&1 && netstat -i || :
    type -p netstat > /dev/null 2>&1 && netstat -x || :
    type -p ip > /dev/null 2>&1 && ip link || :
    type -p ss > /dev/null 2>&1 && ss -x   || :
fi
#
%install
#
# Clean
#
find modules/clx/ -name '*.demos' | xargs --no-run-if-empty rm -vf
#
# Current system
#
SYSTEM=${RPM_ARCH}-suse-linux
LSPDOC=%{_docdir}/clisp
DOCDOC=${LSPDOC}/doc
CLXDOC=${LSPDOC}/clx
LSPLIB=%{_libdir}/clisp-%{version}
CLXLIB=${LSPLIB}/full
#
# Install the current system
#
setarch $(uname -m) -R make -C build install prefix=%{_prefix}   \
        exec_prefix=%{_prefix}      \
        mandir=%{_mandir}       \
        libdir=%{_libdir}       \
    DESTDIR=%{buildroot}        \
    INSTALL_DATA="install -cm 0444"

#
# The CLX interface
#
install -d %{buildroot}${CLXDOC}
install -d %{buildroot}${CLXLIB}
pushd modules/clx/new-clx/
  install -c -m 0444 README %{buildroot}${CLXDOC}/
  install -c -m 0444 %{S:4} %{buildroot}${CLXDOC}/
  tar cf - demos/ | (cd %{buildroot}${CLXDOC}/ ; tar xf - )
popd
pushd modules/clx/
  tar xfz clx-manual.tar.gz -C %{buildroot}${CLXDOC}
popd
find %{buildroot} -name "*.a" | xargs chmod u+w
chmod    u+xrw,a+rx %{buildroot}%{_bindir}/clisp
chmod    u+xrw,a+rx %{buildroot}%{_bindir}/clisp-link
chmod -R g+r,o+r    %{buildroot}${LSPDOC}/
chmod    a-x        %{buildroot}${CLXDOC}/clx-manual/html/doc-index.cgi
find   %{buildroot}${LSPDOC} -type d | xargs chmod 755
rm -f  %{buildroot}${CLXDOC}/*,v
rm -f  %{buildroot}${CLXDOC}/.\#*
rm -f  %{buildroot}${CLXDOC}/demos/*,v
rm -f  %{buildroot}${CLXDOC}/demos/.\#*
rm -f  %{buildroot}${CLXDOC}/demos/*.orig
find   %{buildroot}${LSPLIB}/ -name '*.dvi' | xargs -r rm -f
find   %{buildroot}${LSPLIB}/ -name '*.run' | xargs -r chmod 0755
rm -rf %{buildroot}${LSPLIB}/new-clx/demos/
find   %{buildroot} -type f | xargs -r chmod u+w
chmod a+x %{buildroot}${LSPLIB}/build-aux/{config,depcomp}*
%fdupes %{buildroot}${LSPLIB}/
%find_lang clisp
%find_lang clisplow clisp.lang

%files -f clisp.lang
%defattr(-,root,root,755)
%{_bindir}/clisp
%{_bindir}/clisp-link
%{_libdir}/clisp-%{version}/
%{_datadir}/aclocal/clisp.m4
%{_datadir}/emacs/site-lisp/
%doc %{_datadir}/man/man1/clisp*.1.gz
%{vimdir}/lisp.vim

%files doc
%defattr(-,root,root,755)
%{_docdir}/clisp/

%changelog
* Thu Sep 14 2017 werner@suse.de
- cfree() is missed now in (g)libc
* Thu Jul 27 2017 werner@suse.de
- Try to build on all platforms with new configure option
  - -enable-portability ... let us see if this works
* Thu Jul 27 2017 werner@suse.de
- Update to Mercurial source code from 2017/06/25
  aka test version 2.49.60+
- Modify the patches
  * clisp-2.49-configure.dif
  * clisp-2.49-gctoken.dif
  * clisp-2.49-rpath.dif
  * clisp-arm.patch
  * clisp-link.dif
- Remove patch modules_readline_readline.lisp.patch
  as now the version of readline library is automatically detected
* Fri Feb 10 2017 werner@suse.de
- Collect some informations on the build system for debugging
  a random error on sockets during test suite
* Thu Jan 19 2017 werner@suse.de
- Remove -L option on screen call dues API change, now we depend
  on environment variables only.
* Tue Nov 29 2016 werner@suse.de
- Update to Mercurial source code from 2016/11/28
  * which shows 2630 new lines in src/Changelog
  * Support of new CPU types as well as better 64bit architectures
- Remove patches clisp-glibc-fix.patch and clisp-hostname.patch
  as now upstream
- Modify the patches
    clisp-2.39-clx.dif
    clisp-2.39-ia64-wooh.dif
    clisp-2.49-clx_demos.dif
    clisp-2.49-configure.dif
    clisp-2.49-personality.patch
    clisp-2.49-rpath.dif
    clisp-db6.diff
    clisp-linux.patch
- Add patch clisp-link.dif to get module asdf for console
  support well done
* Thu Oct 27 2016 werner@suse.de
- Add patch modules_readline_readline.lisp.patch to reflect the
  API change in libreadline in rl_readline_state(3) (boo#1007196)
* Fri Aug 14 2015 normand@linux.vnet.ibm.com
- add ppc64le to list of ExcludeArch
  related to src/lispbibl.d "CLISP not ported to this platform"
* Sat Jun 15 2013 jengelh@inai.de
- Add clisp-db6.diff to resolve compile abort with libdb-6.0
- Remove unused %%xarch macro; use automirror-selection Source URL
* Tue May 14 2013 werner@suse.de
- Reintroduce my old patches
  + clisp-2.49-configure.dif -- Make sure to be able to use MYCLFAGS
  + clisp-2.49-gctoken.dif -- Make sure to use initialized token on
    garbage collection
  + clisp-2.49-clx_demos.dif -- Make CLX demos usable at runtime
  + clisp-2.49-postgresql.dif -- Enable postgresql SSL feature
  + re-add clisp-2.49-rpath.dif -- Do not use rpath but rpath-link
- Re-enable test suite
- Use screen to have a terminla around even in build system
* Thu Apr 18 2013 leviathanch@opensuse.org
-  This (split up) package is one of three changes in order to make
  clisp build on armv7l and other platforms. (SR#172680)
* Wed Apr  3 2013 dvaleev@suse.com
- src/socket.d (get_hostname): turn into a function and allocate the
  array in the caller to support gcc 4.7 [patch#3474660]
  fixes ppc socket.d failing test. (clisp-hostname.patch)
* Wed Nov 28 2012 toganm@opensuse.org
- Fix build with glibc 2.17 (clisp-glibc-fix.patch)
  * rebase patches to -p1 as stated in the patching guidelines
  * update to libsegsev-2.10
* Fri Jul 27 2012 aj@suse.de
- Fix build with glibc 2.16 (clisp-linux.patch taken from Fedora).
* Fri Jul 13 2012 adrian@suse.de
- disable stackoverflow tests in qemu builds (fixes arm)
* Wed Apr 18 2012 dvaleev@suse.com
- fix libsigsegv link. To make service run happy
* Tue Mar 27 2012 sweet_f_a@gmx.de
- update to libsigsegv 2.9 to fix ppc build
* Tue Jan 17 2012 sweet_f_a@gmx.de
- don't use deprecated macro suse_update_config
- remove berkeley-db.dif
- strip needs writable files
* Sun Dec 18 2011 sweet_f_a@gmx.de
- minor portability fixes:
  * don't call autoreconf for libsigsegv (not needed since sigsegv patch
    has been removed in lately)
  * require fdupes, dbus-1-devel and xorg-x11-devel only on recent suse
* Mon Dec  5 2011 werner@suse.de
- Use _service to avoid silly osc checks
* Fri Dec  2 2011 werner@suse.de
- Avoid download of ffcall-1.10+2.43
- Convert libsigsegv-2.6.tar from bz2 to gz as build system is not
  smart enough to detect and change the compression format
* Fri Dec  2 2011 coolo@suse.com
- add automake as buildrequire to avoid implicit dependency
* Sat Sep 17 2011 jengelh@medozas.de
- Remove redundant tags/sections from specfile
* Wed Oct  6 2010 aj@suse.de
- Use fdupes
- Fix rpmlintrc for lib64.
* Thu Jul 15 2010 werner@suse.de
- Update 2.49
  * FFI:OPEN-FOREIGN-LIBRARY now accepts the :REQUIRE argument.
  * New user variable CUSTOM:*USER-LIB-DIRECTORY* is respected by REQUIRE
    and used by "clisp-link install".
    Dynamic modules are now the default build option.
  * Function RENAME-FILE now accepts :IF-EXISTS argument which determines
    the action when the destination exists, unless, of course, *ANSI* is T.
  * The replacement value entered by the user in STORE-VALUE and USE-VALUE
    restarts is now EVALuated.
  * The old user variable CUSTOM:*PRINT-CLOSURE* now controls interpreted
    closure output too (RFE#3001956). This is a tricky feature, read up!
  * Module readline now supports readline 6.1.
  * Module pcre now supports pcre 8.01.
  * Module libsvm does not come with the upstream sources anymore, install
    locally and pass --with-libsvm-prefix to the top-level configure instead.
    All upstream versions up to 2.91 are supported.
  * Module berkeley-db now supports Berkeley-DB 4.8.
  * Module postgresql now supports PostgreSQL 8.4.
  * Module pari has been updated to support both 64 & 32 bit platforms
    with and without GMP.
  * New functions OS:VERSION-COMPARE et al call strverscmp.
  * Multiple threads of execution are now experimentally supported
    (not ready for prime time yet).
  * Module libsvm has been upgraded to the upstream version 2.89.
  * Module Berkeley-DB now supports Berkeley DB 4.7.
    (older versions 4.* are, of course, still supported).
  * Module readline now supports readline 6.0.
    (older versions 5.* are, of course, still supported).
  * Passing :EXECUTABLE 0 to EXT:SAVEINITMEM results in an executable
    image which delegates processing of all the usual CLISP command line
    options to the :INIT-FUNCTION.
  * Driver clisp accepts "-b" to print the installation directory.
  * Add file clisp.m4 so that the packages which use CLISP can check
    whether it is properly installed and has the required version.
  * POSIX:COPY-FILE now accepts :METHOD :HARDLINK-OR-COPY.
  * New function POSIX:WAIT calls waitpid or wait4.
  * New function EXT:TRIM-IF removes leading and trailing matches.
  * New user command "LocalSymbols" (abbreviated ":ls").
  * Commands "add" and "create" replace "add-module-set", "add-module-sets" and
    "create-module-set" in clisp-link.
  * New module DBUS interfaces to the D-Bus message bus system.
  * New function EXT:PROBE-PATHNAME can figure out whether the existing
    pathname refers to a file or a directory.
  * New function EXT:CANONICALIZE lets you easily canonicalize a value
    before processing it.
  * New user variable CUSTOM:*REOPEN-OPEN-FILE* controls CLISP behavior
    when opening an already open file.
  * New SETFable function OS:FILE-SIZE extends FILE-LENGTH to pathname
    designators and lets you change file size.
    New function OS:USER-SHELLS returns the list of legal user shells.
    New SETFable functions OS:HOSTID and OS:DOMAINNAME.
  * LOAD now uses DIRECTORY only for wild *LOAD-PATHS* components, thus
    speeding up the most common cases and preventing the denial-of-service
    attack whereas CLISP would not start if a file with a name
    incompatible with *PATHNAME-ENCODING* is present in USER-HOMEDIR-PATHNAME.
  * ROOM now prints some GC statistics and returns the same values as GC.
  * New user variable CUSTOM:*HTTP-LOG-STREAM* controls EXT:OPEN-HTTP logging.
  * CLISP built natively on 64-bit platforms (i.e., with 64-bit pointers)
    now has :WORD-SIZE=64 in *FEATURES*.
  * Module syscalls now offers OS:ERRNO and OS:STRERROR (for the sake of
    FFI modules).
  * Modules MIT-CLX and NEW-CLX export a new macro XLIB:WITH-OPEN-DISPLAY.
  * Module netica has been upgraded to the Netica C API version 3.25 (from 2.15).
  * Module libsvm has been upgraded to the upstream version 2.86.
  * The top-level configure option --build has been replaced by --cbc
    (Configure/Build/Check) to avoid conflict with the standard autoconf option.
  * Experimental Just-In-Time Compilation of byte-compiled closures is now
    done using GNU lightning (this is a configure-time option).
  * New command-line option -lp adds directories to *LOAD-PATHS*.
  * New function FFI:OPEN-FOREIGN-LIBRARY allows pre-opening of shared libraries.
  * New macro EXT:COMPILE-TIME-VALUE allows computing values at file compilation.
  * New function FFI:FOREIGN-POINTER-INFO allows some introspection.
  * Versioned library symbols are now accessible via the :VERSION argument of
    DEF-CALL-OUT and DEF-C-VAR.
  * New functions GRAY:STREAM-READ-SEQUENCE and GRAY:STREAM-WRITE-SEQUENCE have
    been added for portability reasons.
  * New user variable CUSTOM:*SUPPRESS-SIMILAR-CONSTANT-REDEFINITION-WARNING*
    controls whether the redefinition warning is issues when the new
    constant value is visually similar to the old one.
  * REPL commands can now accept arguments.
  * Bug fixes:
    + Do not eliminate function calls which are advertised to have
    exceptional situation in unsafe code (bug#2868166).
    + Fix an internal error in DECLAIM on bad OPTIMIZE quality (bug#2868147).
    + CLEAR-INPUT now clears the EOF condition on file streams (bug#2902716).
    + When quitting on a signal, never enter the debugger (bug#2795278).
    + Respect :FULL T in DIRECTORY :WILD-INFERIORS (bug#3009966).
    + Handle TWO-WAY-STREAM and ECHO-STREAM correctly by
    (SETF STREAM-EXTERNAL-FORMAT) (bug#3020933).
    + Fix unbuffered output pipe stream initialization (bug#3024887).
    + Better support of :START and :END arguments in NEW-CLX (bug#2159172).
    + Fix LOAD-LOGICAL-PATHNAME-TRANSLATIONS when *LOAD-PATHS* contains
    wild pathnames (introduced in 2.47) (bug#2198109).
    + Module NEW-CLX now has the XLIB:QUEUE-EVENT function,
    + Extend the domain of LOG to larger BIGNUMs and RATIOs (bug#1007358).
    + Avoid a segfault on (EXPT <HUGE> <HUGE>) (bug#2807311).
    + Fix interaction of finalizers and weak objects (bug#1472478).
    + Comparison of floats and rationals never underflows (bug#2014262).
    + When failing to convert a huge LONG-FLOAT to a RATIONAL, signal an
    ARITHMETIC-ERROR instead of blowing the stack (bug#2015118).
    + Restored TYPECODES g++ compilation (bug#1385641), which allowed fixing
    a few GC-safety bugs.
    + Fixed a segfault when signaling some UNBOUND-VARIABLE errors in some
    interpreted code on MacOS X (introduced in 2.46) (bug#2020784).
    + Fixed input after switching a :DOS stream to binary (bug#2022362).
    + Support circular objects in EQUAL and EQUALP hash-tables (bug#2029069).
    + Avoid C namespace pollution (bug#2146126).
    + Fix timeout precision in NEW-CLX (bug#2188102).
    + Work around the absence of tgamma on solaris (bug#1966375).
    + Avoid a rare segfault on SIGHUP (bug#1956715).
    + Improve module portability to systems with non-GNU make (bug#1970141).
    + Fix GRAY:STREAM-READ-SEQUENCE and GRAY:STREAM-WRITE-SEQUENCE (bug#1975798).
    + Fix the remaining bugs in special bindings in evaluated code on
    TYPECODES (64-bit) platforms.
    + Fix SOCKET:SOCKET-CONNECT with timeout to a dead port (bug#2007052).
    + Fix handling of quoted objects by READ-PRESERVING-WHITESPACE (bug#1890854).
    + Fix rectangle count in NEW-CLX XLIB:SET-GCONTEXT-CLIP-MASK (bug#1918017).
    + Fix argument handling in NEW-CLX XLIB:QUERY-COLORS (bug#1931101).
    + Fix compilation on systems not supporting returning void (bug#1924506).
    + Fix TANH floating point overflow for large floats (bug#1683394).
    + Avoid extra aggressive bignum overflow reporting in READ (bug#1928735).
    + Improved floating point number formatting. (bug#1790496, bug#1928759)
    + COMPILE no longer discards MACRO doc strings (bug#1936255).
    + Improved accuracy of LOG on complex numbers (bug#1934968).
    + Fix COERCE for compound float result-types (bug#1942246).
    + Fix $http_proxy parsing (bug#1959436).
    + Fix LISTEN on buffered streams when the last character was
    CRLF (bug#1961475).
    + Cross-compilation process has been restored to its former glory,
    thanks to the valiant and persistent testing by
    (bug#1928920, bug#1929496, bug#1929516, bug#1931097)
  * ANSI compliance:
    + Implement the ANSI issue COMPILER-DIAGNOSTICS:USE-HANDLER: use the
    CL Condition System for compiler diagnostics.
    + STREAM-ELEMENT-TYPE on empty CONCATENATED-STREAMs now returns NIL
    because nothing can be read from such streams (bug#3014921).
    + Implement the ANSI (IGNORE #'FUNCTION) declaration.
    + The sets of declaration and type names are disjoint.
    + FLET, LABELS and MACROLET respect declarations.
* Wed Apr 21 2010 coolo@novell.com
- found patch to avoid endless configure
* Tue Nov  3 2009 coolo@novell.com
- updated patches to apply with fuzz=0
* Wed Aug 26 2009 mls@suse.de
- make patch0 usage consistent
* Thu Mar  5 2009 crrodriguez@suse.de
- build this package against newer Berkeley DB, so db43 can be
  dropped as nothing else depends on it.
* Tue Feb 26 2008 werner@suse.de
- Update 2.44.1
  * Portability:
    + Add a workaround against a gcc 4.2.x bug.
    + Make it work with gcc 4.3 snapshots.
  * CLISP does not come with GNU libffcall anymore.
    This is now a separate package and should be installed separately.
    Pass --with-libffcall-prefix to the top-level configure if it is not
    installed in a standard place.
    Option --with-dynamic-ffi is now replaced with --with-ffcall.
  * CLOS now issues warnings of type CLOS:CLOS-WARNING.
    See <http://clisp.cons.org/impnotes/mop-clisp.html#mop-clisp-warn>
    for details.
  * The AFFI (simple ffi, originally for Amiga) code has been removed.
  * Speed up list and sequence functions when :TEST is EQ, EQL, EQUAL or EQUALP.
  * Rename EXT:DELETE-DIR, EXT:MAKE-DIR, and EXT:RENAME-DIR to
    EXT:DELETE-DIRECTORY, EXT:MAKE-DIRECTORY, and EXT:RENAME-DIRECTORY,
    respectively, for consistency with EXT:PROBE-DIRECTORY,
    EXT:DEFAULT-DIRECTORY and CL:PATHNAME-DIRECTORY.
    The old names are still available, but deprecated.
  * The :VERBOSE argument to SAVEINITMEM defaults to a new user variable
  * SAVEINITMEM-VERBOSE*, intial value T.
    See <http://clisp.cons.org/impnotes/image.html> for details.
  * Bug fixes:
    + Fix FRESH-LINE at the end of a line containing only TABs. [ 1834193 ]
    + PPRINT-LOGICAL-BLOCK no longer ignores *PRINT-PPRINT-DISPATCH-TABLE*.
    [ 1835520 ]
    + BYTE is now a full-fledged type. [ 1854698 ]
    + Fix linux:dirent definition in the bindings/glibc module. [ 1779490 ]
    + Symbolic links into non-existent directories can now be deleted. [ 1860489 ]
    + DIRECTORY :FULL on directories now returns the same information as
    on files. [ 1860677 ]
    + CLISP no longer hangs at the end of a script coming via a pipe
    ("clisp < script.lisp" or "cat script | clisp"). [ 1865567 ]
    + When *CURRENT-LANGUAGE* is incompatible with *TERMINAL-ENCODING*,
    CLISP no longer goes into an infinite recursion trying to print
    various help messages. [ 1865636 ]
    + Fix the "Quit" debugger command. [ 1448744 ]
    + Repeated terminating signals kill CLISP instantly with the correct
    exit code. [ 1871205 ]
    + Stack inspection is now safer. [ 1506316 ]
    + Errors in the RC-file and init files are now handled properly. [ 1714737 ]
    + Avoid the growth of the restart set with each image save. [ 1877497 ]
    + Handle foreign functions coming from the old image which cannot be
    validated. [ 1407486 ]
    + Fix signal code in bindings/glibc/linux.lisp. [ 1781476 ]
* Thu Jan 24 2008 werner@suse.de
- Correct vim site path to current used one
* Sun Jan 13 2008 coolo@suse.de
- fix file list for vim
* Tue Dec 18 2007 werner@suse.de
- Use -ffloat-store on on i386 to avoid the previous bug
- Reorder -f options and -D defines of gcc
* Mon Dec 17 2007 werner@suse.de
- Add workaround to gcc bug in -O2 on i386
* Fri Dec 14 2007 werner@suse.de
- Update to 2.43
  * Infrastructure:
    + Top-level configure now accepts a new option --vimdir which specifies
    the installation directory for the VIM files (lisp.vim).
    The default value is ${datadir}/vim/vimfiles/after/syntax/.
    Thus, lisp.vim is now installed by "make install", and should
    be included in the 3rd party distributions.
    + Top-level configure now always runs makemake, and makemake no longer is
    a "user-level" command; do not run it unless you know what you are doing.
    This brings the CLISP build process in compliance with the GNU standards.
    + We now use gnulib-tool to sync with gnulib (not really user visible,
    but a major infrastructure change).
  * Portability:
    + Support for ancient systems with broken CPP have been dropped.
    This includes AIX 4.2, Coherent386, Ultrix, MSVC4, MSVC5.
    + NeXT application (GUI) code has been removed. Plain TTY is still supported.
  * Module berkeley-db now supports Berkeley DB 4.5 & 4.6.
  * Bug fixes:
    + FORCE-OUTPUT breakage on MacOS X when stdout is not a terminal. [ 1827572 ]
    + Fixed *PRINT-PPRINT-DISPATCH* binding in WITH-STANDARD-IO-SYNTAX.
    [ 1831367 ]
- Update to 2.42
  * New module gtk2 interfaces to GTK+ v2 and makes it possible to build
    GUI with Glade.
    Thanks to James Bailey <dgym.bailey@gmail.com> for the original code.
    See <http://clisp.cons.org/impnotes/gtk.html> for details.
  * New module gdbm interfaces to GNU DataBase Manager.
    Thanks to Masayuki Onjo <masayuki.onjo@gmail.com>.
    See <http://clisp.cons.org/impnotes/gdbm.html> for details.
  * A kind of Meta-Object Protocol for structures is now available.
    See <http://clisp.cons.org/impnotes/defstruct-mop.html> for details.
  * Module libsvm has been upgraded to the upstream version 2.84.
    See <http://clisp.cons.org/impnotes/libsvm.html> for details.
  * NEW-CLX module now supports Stumpwm <http://www.nongnu.org/stumpwm/>.
    Thanks to Shawn Betts <sabetts@vcn.bc.ca>.
    New NEW-CLX demos: bball bwindow greynetic hanoi petal plaid recurrence from
    <http://www.cs.cmu.edu/afs/cs/project/ai-repository/ai/lang/lisp/gui/clx/clx_demo.cl>.
    New NEW-CLX demo: clclock based on <http://common-lisp.net/~crhodes/clx>.
    New function XLIB:OPEN-DEFAULT-DISPLAY from portable CLX.
  * Function EXT:ARGLIST now works on macros too.
    See <http://clisp.cons.org/impnotes/flow-dict.html#arglist> for details.
  * Macro TRACE has a new option :BINDINGS, which is useful to share data
    between PRE-* and POST-* forms.
    See <http://clisp.cons.org/environment-dict.html#trace> for details.
  * Macro FFI:DEF-C-TYPE can now be called with one argument to define an
    integer type.
    See <http://clisp.cons.org/impnotes/dffi.html#def-c-type> for details.
  * New function EXT:RENAME-DIR can be used to rename directories.
    See <http://clisp.cons.org/impnotes/file-dict.html#rename-dir> for details.
  * Functions FILE-LENGTH and FILE-POSITION now work on unbuffered streams too.
    See  <http://clisp.cons.org/impnotes/stream-dict.html#file-pos> for details.
  * Bug fixes:
    + Fixed EXT:LETF to work with more than one place. [ 1731462 ]
    + Fixed rounding of long floats [even+1/2]. [ 1589311 ]
    + Fixed stdio when running without a TTY, e.g., under SSH. [ 1592343 ]
    + ANSI compliance: PPRINT dispatch is now respected for nested
    objects, not just the top-level. [ 1483768, 1598053 ]
    + Fixed print-read-consistency of strings containing #\Return characters
    (manifested by COMPILE-FILE). [ 1578179 ]
    + Fixed "clisp-link run". [ 1469663 ]
    + Fixed ATANH branch cut continuity. [ 1436987 ]
    + Reset the function lambda expression when loading a compiled file.
    [ 1603260 ]
    + DOCUMENTATION set by SETF is now preserved by COMPILE. [ 1604579 ]
    + LISTEN now calls STREAM-LISTEN as per the Gray proposal. [ 1607666 ]
    + IMPORT into the KEYWORD package does not make a symbol a constant
    variable. [ 1612859 ]
    + DEFPACKAGE code was executed during non top-level compilation. [ 1612313 ]
    + Fixed format error message formatting. [ 1482465 ]
    + Fixed *PPRINT-FIRST-NEWLINE* handling. [ 1412454 ]
    + Improved hash code generation for very large bignums and for long lists.
    [ 948868, 1208124 ]
    + Some bugs related to UNICODE-16 & UNICODE-32. [ 1564818, 1631760, 1632718 ]
    + All exported defined symbols are now properly locked. [ 1713130 ]
    + Berkeley-DB module no longer fills up error log file. [ 1779416 ]
    + New-clx now supports 64-bit KeySym. [ 1797132 ]
* Tue May 22 2007 ro@suse.de
- update to 2.41
  * New module libsvm interfaces to <http://www.csie.ntu.edu.tw/~cjlin/libsvm>
    and makes Support Vector Machines available in CLISP.
    See <http://clisp.cons.org/impnotes/libsvm.html> for details.
  * The same internal interface now handles FFI forms DEF-CALL-OUT and
    DEF-C-VAR regardless of the presence of the :LIBRARY argument.
    (:LIBRARY NIL) is now identical to omitting the :LIBRARY argument.
    The default for the :LIBRARY argument is set by
    FFI:DEFAULT-FOREIGN-LIBRARY per compilation unit.
    See <http://clisp.cons.org/impnotes/dffi.html#dffi-default-lib> for details.
  * Bug fixes:
    + DOCUMENTATION on built-in functions was broken on some platforms.
    [ 1569234 ]
    + Fixed FFI callbacks, broken since the 2.36 release.
    + Fixed the way the top-level driver handles the "--" option terminator.
    + Fixed COMPILE of APPLY in LABELS for local function. [ 1575946 ]
- update to 2.40
  Important notes
  - --------------
  * All .fas files generated by previous CLISP versions are invalid and
    must be recompiled.  This is because DOCUMENTATION and LAMBDA-LIST are
    now kept with the closures.
    Set CUSTOM:*LOAD-OBSOLETE-ACTION* to :COMPILE to automate this.
    See <http://clisp.cons.org/impnotes/system-dict.html#loadfile> for details.
  User visible changes
  - -------------------
  * Infrastructure
    + Top-level configure now accepts a new option --elispdir which specifies
    the installation directory for the Emacs Lisp files (clhs.el et al).
    The default value is ${datadir}/emacs/site-lisp/.
    Thus, clhs.el at al are now installed by "make install", and should
    be included in the 3rd party distributions.
    + Top-level configure now accepts variables on command line, e.g.,
    ./configure CC=g++ CFLAGS=-g
  * Function PCRE:PCRE-EXEC accepts :DFA and calls pcre_dfa_exec() when
    built against PCRE v6.  See <http://clisp.cons.org/impnotes/pcre.html>.
  * New functions RAWSOCK:IF-NAME-INDEX, RAWSOCK:IFADDRS.
    See <http://clisp.cons.org/impnotes/rawsock.html>.
  * When the OPTIMIZE SPACE level is low enough, keep function
    documentation and lambda list.
    See <http://clisp.cons.org/impnotes/declarations.html#space-decl>.
  * Bug fixes:
    + Make it possible to set *IMPNOTES-ROOT-DEFAULT* and *CLHS-ROOT-DEFAULT*
    to local paths, as opposed to URLs. [ 1494059 ]
    + Fix the evaluation order of initialization and :INITIALLY forms in
    then extended LOOP. [ 1516684 ]
    + Do not allow non-symbols as names of anonymous classes. [ 1528201 ]
    + REINITIALIZE-INSTANCE now calls FINALIZE-INHERITANCE. [ 1526448 ]
    + Fix the RAWSOCK module on big-endian platforms. [ 1529244 ]
    + PRINT-OBJECT now works on built-in objects.  [ 1482533 ]
    + ADJUST-ARRAY signals an error if :FILL-POINTER is supplied and non-NIL
    but the non-adjustable array has no fill pointer, as per ANSI. [ 1538333 ]
    + MAKE-PATHNAME no longer ignores explicit :DIRECTORY NIL (thanks to
    Stephen Compall <s11001001@users.sourceforge.net>). [ 1550803 ]
    + Executable images now work on ia64 (thanks to Dr. Werner Fink
    <werner@suse.de>).
    + MAKE-PATHNAME on win32 now handles correctly directories that start
    with a non-string (e.g., :WILD). [ 1555096 ]
    + SOCKET-STREAM-PEER and SOCKET-STREAM-LOCAL had do-not-resolved-p
    inverted since 2.37.
    + Set functions with :TEST 'EQUALP were broken on large lists. [ 1567186 ]
* Mon Apr 23 2007 aj@suse.de
- Remove unneeded BuildRequires.
* Wed Jan 24 2007 werner@suse.de
- Stop compiler complaining about x = x++
- Use db-4.3 instead of db-4.4, the breaking all former versions
* Sun Oct 29 2006 ro@suse.de
- disabled berkeley-db module for the moment to fix build
  needs porting to db-4.4
* Wed Jul 19 2006 werner@suse.de
- Update to clisp version 2.39
  * Many bug fixes and new features
- With a real bug fix for last crash on ia64
- Add a new workaround for a new random crash on ia64
* Thu Jun 22 2006 ro@suse.de
- remove self provides
* Tue May 23 2006 werner@suse.de
- Skip exec-image test on ia64, currently broken
- Use noexec heap codes on 32 bit architectures
* Mon May 22 2006 werner@suse.de
- Update to clisp 2.38
* Tue Mar 21 2006 werner@suse.de
- Be sure not to be fooled by old kernels on IA64
* Mon Mar 13 2006 werner@suse.de
- Be sure that the stack size limit is large enough to be able
  to dump the resulting clisp image.
* Sun Feb  5 2006 schwab@suse.de
- Remove ridiculous stack limit.
* Wed Jan 25 2006 mls@suse.de
- converted neededforbuild to BuildRequires
* Tue Jan 10 2006 werner@suse.de
- Update to bug fix release 2.37
* Wed Dec 21 2005 werner@suse.de
- Make the factorials of 17 upto 33 work on 64 bit without SIGSEGV
* Wed Dec  7 2005 werner@suse.de
- Update to clisp 2.36
* Mon Sep  5 2005 werner@suse.de
- Update to clisp 2.35
* Thu Apr 14 2005 werner@suse.de
- Get clisp back on ix86
* Wed Jan 12 2005 mfabian@suse.de
- Bugzilla #39700: apply patch received from Bruno Haible to fix
  a problem with non-ASCII file names.
* Tue Oct 26 2004 werner@suse.de
- Switch from heimdal-lib to kerberos-devel-packages macro
* Wed Jun 30 2004 werner@suse.de
- Handle axp just as ia64 in CFLAGS to make it work correctly
* Tue Jun 29 2004 werner@suse.de
- Make FFI work on ia64
- Make memory mapping of lisp object work correctly on ia64
* Wed Jun 23 2004 werner@suse.de
- Update to clisp 2.33.2
- Make it work on x86_64
- Use FFI on s390 because it works
- Currently disable FFI in ia64 because it does not work
* Fri Feb 20 2004 werner@suse.de
- Back to clisp 2.30 because 2.32/2.31 does _not_ support 64bit
  systems (work in progress, waiting on 2.33).  OK, with 2.30
  and current compiler no of 64 bit systems are running, but
  we get abck a s390 clisp version.
* Fri Feb 13 2004 kukuk@suse.de
- Build as normal user
- Cleanup neededforbuild
* Fri Feb 13 2004 werner@suse.de
- Update to clisp 2.32
* Wed Nov 19 2003 max@suse.de
- Linking libpq dynamically, because it now depends on libkrb5.
- Added heimdal-lib (libkrb5) to neededforbuild.
* Thu Jun 12 2003 coolo@suse.de
- use BuildRoot
- use %%find_lang
* Wed Jun 11 2003 kukuk@suse.de
- Fix tail parameters
- Fix filelist
* Wed Jan 29 2003 werner@suse.de
- Get it running with gcc 3.3, with this compiler the TYPECODES
  can not determined anymore and uses NO_TYPECODES.
* Fri Jan 24 2003 werner@suse.de
- Update to 2.30
* Mon Nov 11 2002 ro@suse.de
- changed neededforbuild <xshared> to <x-devel-packages>
- changed neededforbuild <xdevel> to <>
* Thu Aug  1 2002 werner@suse.de
- Make it work on i386, on others gcc 3.1 runs into problems
* Wed Jul 31 2002 werner@suse.de
- Update to 2.29 (mainly for gcc 3.1)
- Use SAFETY=3 for some architectures (currently for
  sparc sparcv9 sparc64 s390 s390x x86_64)
- Replace config.guess within all autoconf directories (ppc64?)
* Wed Jun 26 2002 aj@suse.de
- First draft for x86-64.  Still work needed for avcall.
* Wed Jun 26 2002 ro@suse.de
- update to 2.28
- build again with gcc-3.1 (use -fno-gcse and -DNO_ASM as proposed)
- use -fPIC for files linked into shared lib
- still needs some porting for x86_64 (processor-defs in lispbibl.d)
* Sun Jun 23 2002 ro@suse.de
- fix permissions for doc directories
* Sat Jun  1 2002 adrian@suse.de
- fix build on mips
  * fix wrong #includes
  * fix as path /bin/as -> /usr/bin/as
* Wed Aug 22 2001 ro@suse.de
- fixed specfile to build on ppc
* Wed Jul 11 2001 ro@suse.de
- update to 2.26
- no autoconf call at the moment
* Mon May  7 2001 mfabian@suse.de
- bzip2 sources
* Tue Dec  5 2000 werner@suse.de
- Update to 2000.03.06
- Use postgresql and postgresql-devel
- Change libpq paths accordingly to postgresql-devel
- Make clx demos working as found in README
* Fri Dec  1 2000 ro@suse.de
- neededforbuild: postgresql
* Mon Jun  5 2000 uli@suse.de
- moved docs to %%{_docdir}
* Mon Jan 31 2000 ro@suse.de
- fixed libc6-checking again
* Mon Jan 31 2000 werner@suse.de
- Tried to get PPC working (does NOT work)
  - /usr/man -> /usr/share/man
* Thu Oct 28 1999 werner@suse.de
- Reintroduce FIFO hack for a missed tty
* Mon Oct 11 1999 werner@suse.de
- New version clisp-1999-07-22
  * remove Makefile.Linux and use spec instead
* Mon Sep 13 1999 bs@suse.de
- ran old prepare_spec on spec file to switch to new prepare_spec.
* Wed Mar 31 1999 werner@suse.de
- No string inlines
* Tue Mar 30 1999 werner@suse.de
- Work around clisp's buffered *TERMINAL-IO* within a
  background build process
* Mon Mar 29 1999 werner@suse.de
- New version clisp-1999-01-08
  - Make -X and -F identical
* Fri Dec 18 1998 werner@suse.de
- New version clisp-1998-09-09
  - Change option -F (full version) to option -X
  * Split modules into wildcard, regexp, bindings/linuxlibc6 on
  one hand and new-clx on the other one.
  * Replace normal version with full version without new-clx
  * New version including new-clx and all other modules
* Thu Feb 19 1998 werner@suse.de
- New Version 1997-12-06
  - clx script removed
  - Option -F for clisp added
* Mon Jun  9 1997 werner@suse.de
- Patch for GC in clisp included.
* Fri Jun  6 1997 werner@suse.de
- New package: clisp version 1997-05-03
  - Added nclx version 1996-10-12 a
  clx re-implementation of Gilbert Baumann
  - clisp+clx is called with /usr/bin/clx
  clisp is called with /usr/bin/clisp
