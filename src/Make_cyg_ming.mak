# Makefile for VIM on Win32 (Cygwin and MinGW)
#
# This file contains common part for Cygwin and MinGW and it is included
# from Make_cyg.mak and Make_ming.mak.
#
# Info at http://www.mingw.org
# Alternative x86 and 64-builds: http://mingw-w64.sourceforge.net
# Also requires GNU make, which you can download from the same sites.
# Get missing libraries from http://gnuwin32.sf.net.
#
# Tested on Win32 NT 4 and Win95.
#
# To make everything, just 'make -f Make_ming.mak'.
# To make just e.g. gvim.exe, 'make -f Make_ming.mak gvim.exe'.
# After a run, you can 'make -f Make_ming.mak clean' to clean up.
#
# NOTE: Sometimes 'GNU Make' will stop after building vimrun.exe -- I think
# it's just run out of memory or something.  Run again, and it will continue
# with 'xxd'.
#
# "make upx" makes *compressed* versions of the 32 bit GUI and console EXEs,
# using the excellent UPX compressor:
#     http://upx.sourceforge.net/
# "make mpress" uses the MPRESS compressor for 32- and 64-bit EXEs:
#     http://www.matcode.com/mpress.htm
#
# Maintained by Ron Aaron <ronaharon@yahoo.com> et al.
# Updated 2014 Oct 13.

#>>>>> choose options:
# set to yes for a debug build
DEBUG=no
# set to SIZE for size, SPEED for speed, MAXSPEED for maximum optimization
OPTIMIZE=MAXSPEED
# set to yes to make gvim, no for vim
GUI=yes
# set to yes if you want to use DirectWrite (DirectX)
# MinGW-w64 is needed, and ARCH should be set to i686 or x86-64.
DIRECTX=no
# FEATURES=[TINY | SMALL | NORMAL | BIG | HUGE]
# Set to TINY to make minimal version (few features).
FEATURES=HUGE
# Set to one of i386, i486, i586, i686 as the minimum target processor.
# For amd64/x64 architecture set ARCH=x86-64 .
# If not set, it will be automatically detected. (Normally i686 or x86-64.)
#ARCH=i686
# Set to yes to cross-compile from unix; no=native Windows (and Cygwin).
CROSS=no
# Set to path to iconv.h and libiconv.a to enable using 'iconv.dll'.
#ICONV="."
ICONV=yes
GETTEXT=yes
# Set to yes to include multibyte support.
MBYTE=yes
# Set to yes to include IME support.
IME=yes
DYNAMIC_IME=yes
# Set to yes to enable writing a postscript file with :hardcopy.
POSTSCRIPT=no
# Set to yes to enable OLE support.
OLE=no
# Set the default $(WINVER) to make it work with WinXP.
ifndef WINVER
WINVER = 0x0501
endif
# Set to yes to enable Cscope support.
CSCOPE=yes
# Set to yes to enable Netbeans support (requires CHANNEL).
NETBEANS=$(GUI)
# Set to yes to enable inter process communication.
ifeq (HUGE, $(FEATURES))
CHANNEL=yes
else
CHANNEL=$(GUI)
endif


# Link against the shared version of libstdc++ by default.  Set
# STATIC_STDCPLUS to "yes" to link against static version instead.
ifndef STATIC_STDCPLUS
STATIC_STDCPLUS=no
endif


# Link against the shared version of libwinpthread by default.  Set
# STATIC_WINPTHREAD to "yes" to link against static version instead.
ifndef STATIC_WINPTHREAD
STATIC_WINPTHREAD=$(STATIC_STDCPLUS)
endif

# If the user doesn't want gettext, undefine it.
ifeq (no, $(GETTEXT))
GETTEXT=
endif
# Added by E.F. Amatria <eferna1@platea.ptic.mec.es> 2001 Feb 23
# Uncomment the first line and one of the following three if you want Native Language
# Support.  You'll need gnu_gettext.win32, a MINGW32 Windows PORT of gettext by
# Franco Bez <franco.bez@gmx.de>.  It may be found at
# http://home.a-city.de/franco.bez/gettext/gettext_win32_en.html
# Tested with mingw32 with GCC-2.95.2 on Win98
# Updated 2001 Jun 9
#GETTEXT=c:/gettext.win32.msvcrt
#STATIC_GETTEXT=USE_STATIC_GETTEXT
#DYNAMIC_GETTEXT=USE_GETTEXT_DLL
#DYNAMIC_GETTEXT=USE_SAFE_GETTEXT_DLL
SAFE_GETTEXT_DLL_OBJ = $(GETTEXT)/src/safe_gettext_dll/safe_gettext_dll.o
# Alternatively, if you uncomment the two following lines, you get a "safe" version
# without linking the safe_gettext_dll.o object file.
#DYNAMIC_GETTEXT=DYNAMIC_GETTEXT
#GETTEXT_DYNAMIC=gnu_gettext.dll
INTLPATH=$(GETTEXT)/lib/mingw32
INTLLIB=gnu_gettext

# If you are using gettext-0.10.35 from http://sourceforge.net/projects/gettext
# or gettext-0.10.37 from http://sourceforge.net/projects/mingwrep/
# uncomment the following, but I can't build a static version with them, ?-(|
#GETTEXT=c:/gettext-0.10.37-20010430
#STATIC_GETTEXT=USE_STATIC_GETTEXT
#DYNAMIC_GETTEXT=DYNAMIC_GETTEXT
#INTLPATH=$(GETTEXT)/lib
#INTLLIB=intl


# Command definitions (depends on cross-compiling and shell)
ifeq ($(CROSS),yes)
# cross-compiler prefix:
ifndef CROSS_COMPILE
CROSS_COMPILE = i586-pc-mingw32msvc-
endif
DEL = rm
MKDIR = mkdir -p
DIRSLASH = /
else
# normal (Windows) compilation:
ifndef CROSS_COMPILE
CROSS_COMPILE =
endif
ifneq (sh.exe, $(SHELL))
DEL = rm
MKDIR = mkdir -p
DIRSLASH = /
else
DEL = del
MKDIR = mkdir
DIRSLASH = \\
endif
endif
CC := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
ifeq ($(UNDER_CYGWIN),yes)
WINDRES := $(CROSS_COMPILE)windres
else
WINDRES := windres
endif
WINDRES_CC = $(CC)

# Get the default ARCH.
ifndef ARCH
ARCH := $(shell $(CC) -dumpmachine | sed -e 's/-.*//' -e 's/_/-/' -e 's/^mingw32$$/i686/')
endif


#	Perl interface:
#	  PERL=[Path to Perl directory] (Set inside Make_cyg.mak or Make_ming.mak)
#	  DYNAMIC_PERL=yes (to load the Perl DLL dynamically)
#	  PERL_VER=[Perl version, eg 56, 58, 510] (default is 524)
ifdef PERL
ifndef PERL_VER
PERL_VER=524
endif
ifndef DYNAMIC_PERL
DYNAMIC_PERL=yes
endif
# on Linux, for cross-compile, it's here:
#PERLLIB=/home/ron/ActivePerl/lib
# on NT, it's here:
PERLEXE=$(PERL)/bin/perl
PERLLIB=$(PERL)/lib
PERLLIBS=$(PERLLIB)/Core
ifeq ($(UNDER_CYGWIN),yes)
PERLTYPEMAP:=$(shell cygpath -m $(PERLLIB)/ExtUtils/typemap)
XSUBPPTRY:=$(shell cygpath -m $(PERLLIB)/ExtUtils/xsubpp)
else
PERLTYPEMAP=$(PERLLIB)/ExtUtils/typemap
XSUBPPTRY=$(PERLLIB)/ExtUtils/xsubpp
endif
XSUBPP_EXISTS=$(shell $(PERLEXE) -e "print 1 unless -e '$(XSUBPPTRY)'")
ifeq "$(XSUBPP_EXISTS)" ""
XSUBPP=$(PERLEXE) $(XSUBPPTRY)
else
XSUBPP=xsubpp
endif
endif

#	Lua interface:
#	  LUA=[Path to Lua directory] (Set inside Make_cyg.mak or Make_ming.mak)
#	  DYNAMIC_LUA=yes (to load the Lua DLL dynamically)
#	  LUA_VER=[Lua version, eg 51, 52] (default is 53)
ifdef LUA
ifndef DYNAMIC_LUA
DYNAMIC_LUA=yes
endif

ifndef LUA_VER
LUA_VER=53
endif

ifeq (no,$(DYNAMIC_LUA))
LUA_LIB = -L$(LUA)/lib -llua
endif

endif

#	MzScheme interface:
#	  MZSCHEME=[Path to MzScheme directory] (Set inside Make_cyg.mak or Make_ming.mak)
#	  DYNAMIC_MZSCHEME=yes (to load the MzScheme DLL dynamically)
#	  MZSCHEME_VER=[MzScheme version] (default is 3m_a0solc (6.6))
#	  MZSCHEME_DEBUG=no
ifdef MZSCHEME
ifndef DYNAMIC_MZSCHEME
DYNAMIC_MZSCHEME=yes
endif

ifndef MZSCHEME_VER
MZSCHEME_VER=3m_a0solc
endif

# for version 4.x we need to generate byte-code for Scheme base
ifndef MZSCHEME_GENERATE_BASE
MZSCHEME_GENERATE_BASE=no
endif

ifneq ($(wildcard $(MZSCHEME)/lib/msvc/libmzsch$(MZSCHEME_VER).lib),)
MZSCHEME_MAIN_LIB=mzsch
else
MZSCHEME_MAIN_LIB=racket
endif

ifndef MZSCHEME_PRECISE_GC
MZSCHEME_PRECISE_GC=no
ifneq ($(wildcard $(MZSCHEME)\lib\lib$(MZSCHEME_MAIN_LIB)$(MZSCHEME_VER).dll),)
ifeq ($(wildcard $(MZSCHEME)\lib\libmzgc$(MZSCHEME_VER).dll),)
MZSCHEME_PRECISE_GC=yes
endif
else
ifneq ($(wildcard $(MZSCHEME)\lib\msvc\lib$(MZSCHEME_MAIN_LIB)$(MZSCHEME_VER).lib),)
ifeq ($(wildcard $(MZSCHEME)\lib\msvc\libmzgc$(MZSCHEME_VER).lib),)
MZSCHEME_PRECISE_GC=yes
endif
endif
endif
endif

ifeq (no,$(DYNAMIC_MZSCHEME))
ifeq (yes,$(MZSCHEME_PRECISE_GC))
MZSCHEME_LIB=-l$(MZSCHEME_MAIN_LIB)$(MZSCHEME_VER)
else
MZSCHEME_LIB=-l$(MZSCHEME_MAIN_LIB)$(MZSCHEME_VER) -lmzgc$(MZSCHEME_VER)
endif
# the modern MinGW can dynamically link to dlls directly.
# point MZSCHEME_DLLS to where you put libmzschXXXXXXX.dll and libgcXXXXXXX.dll
ifndef MZSCHEME_DLLS
MZSCHEME_DLLS=$(MZSCHEME)
endif
MZSCHEME_LIBDIR=-L$(MZSCHEME_DLLS) -L$(MZSCHEME_DLLS)\lib
endif

endif

#	Python interface:
#	  PYTHON=[Path to Python directory] (Set inside Make_cyg.mak or Make_ming.mak)
#	  DYNAMIC_PYTHON=yes (to load the Python DLL dynamically)
#	  PYTHON_VER=[Python version, eg 22, 23, ..., 27] (default is 27)
ifdef PYTHON
ifndef DYNAMIC_PYTHON
DYNAMIC_PYTHON=yes
endif

ifndef PYTHON_VER
PYTHON_VER=27
endif
ifndef DYNAMIC_PYTHON_DLL
DYNAMIC_PYTHON_DLL=python$(PYTHON_VER).dll
endif
ifdef PYTHON_HOME
PYTHON_HOME_DEF=-DPYTHON_HOME=\"$(PYTHON_HOME)\"
endif

ifeq (no,$(DYNAMIC_PYTHON))
PYTHONLIB=-L$(PYTHON)/libs -lpython$(PYTHON_VER)
endif
# my include files are in 'win32inc' on Linux, and 'include' in the standard
# NT distro (ActiveState)
ifndef PYTHONINC
ifeq ($(CROSS),no)
PYTHONINC=-I $(PYTHON)/include
else
PYTHONINC=-I $(PYTHON)/win32inc
endif
endif
endif

#	Python3 interface:
#	  PYTHON3=[Path to Python3 directory] (Set inside Make_cyg.mak or Make_ming.mak)
#	  DYNAMIC_PYTHON3=yes (to load the Python3 DLL dynamically)
#	  PYTHON3_VER=[Python3 version, eg 31, 32] (default is 35)
ifdef PYTHON3
ifndef DYNAMIC_PYTHON3
DYNAMIC_PYTHON3=yes
endif

ifndef PYTHON3_VER
PYTHON3_VER=35
endif
ifndef DYNAMIC_PYTHON3_DLL
DYNAMIC_PYTHON3_DLL=python$(PYTHON3_VER).dll
endif
ifdef PYTHON3_HOME
PYTHON3_HOME_DEF=-DPYTHON3_HOME=L\"$(PYTHON3_HOME)\"
endif

ifeq (no,$(DYNAMIC_PYTHON3))
PYTHON3LIB=-L$(PYTHON3)/libs -lpython$(PYTHON3_VER)
endif

ifndef PYTHON3INC
ifeq ($(CROSS),no)
PYTHON3INC=-I $(PYTHON3)/include
else
PYTHON3INC=-I $(PYTHON3)/win32inc
endif
endif
endif

#	TCL interface:
#	  TCL=[Path to TCL directory] (Set inside Make_cyg.mak or Make_ming.mak)
#	  DYNAMIC_TCL=yes (to load the TCL DLL dynamically)
#	  TCL_VER=[TCL version, eg 83, 84] (default is 86)
#	  TCL_VER_LONG=[Tcl version, eg 8.3] (default is 8.6)
#	    You must set TCL_VER_LONG when you set TCL_VER.
ifdef TCL
ifndef DYNAMIC_TCL
DYNAMIC_TCL=yes
endif
ifndef TCL_VER
TCL_VER = 86
endif
ifndef TCL_VER_LONG
TCL_VER_LONG = 8.6
endif
TCLINC += -I$(TCL)/include
endif


#	Ruby interface:
#	  RUBY=[Path to Ruby directory] (Set inside Make_cyg.mak or Make_ming.mak)
#	  DYNAMIC_RUBY=yes (to load the Ruby DLL dynamically)
#	  RUBY_VER=[Ruby version, eg 19, 22] (default is 22)
#	  RUBY_API_VER_LONG=[Ruby API version, eg 1.8, 1.9.1, 2.2.0]
#			    (default is 2.2.0)
#	    You must set RUBY_API_VER_LONG when changing RUBY_VER.
#	    Note: If you use Ruby 1.9.3, set as follows:
#	      RUBY_VER=19
#	      RUBY_API_VER_LONG=1.9.1 (not 1.9.3, because the API version is 1.9.1.)
ifdef RUBY
ifndef DYNAMIC_RUBY
DYNAMIC_RUBY=yes
endif
#  Set default value
ifndef RUBY_VER
RUBY_VER = 22
endif
ifndef RUBY_VER_LONG
RUBY_VER_LONG = 2.2.0
endif
ifndef RUBY_API_VER_LONG
RUBY_API_VER_LONG = $(RUBY_VER_LONG)
endif
ifndef RUBY_API_VER
RUBY_API_VER = $(subst .,,$(RUBY_API_VER_LONG))
endif

ifndef RUBY_PLATFORM
ifeq ($(RUBY_VER), 16)
RUBY_PLATFORM = i586-mswin32
else
ifneq ($(wildcard $(RUBY)/lib/ruby/$(RUBY_API_VER_LONG)/i386-mingw32),)
RUBY_PLATFORM = i386-mingw32
else
ifneq ($(wildcard $(RUBY)/lib/ruby/$(RUBY_API_VER_LONG)/x64-mingw32),)
RUBY_PLATFORM = x64-mingw32
else
RUBY_PLATFORM = i386-mswin32
endif
endif
endif
endif

ifndef RUBY_INSTALL_NAME
ifeq ($(RUBY_VER), 16)
RUBY_INSTALL_NAME = mswin32-ruby$(RUBY_API_VER)
else
ifndef RUBY_MSVCRT_NAME
# Base name of msvcrXX.dll which is used by ruby's dll.
RUBY_MSVCRT_NAME = msvcrt
endif
ifeq ($(ARCH),x86-64)
RUBY_INSTALL_NAME = x64-$(RUBY_MSVCRT_NAME)-ruby$(RUBY_API_VER)
else
RUBY_INSTALL_NAME = $(RUBY_MSVCRT_NAME)-ruby$(RUBY_API_VER)
endif
endif
endif

ifeq (19, $(word 1,$(sort 19 $(RUBY_VER))))
RUBY_19_OR_LATER = 1
endif

RUBYINC = -I $(RUBY)/lib/ruby/$(RUBY_API_VER_LONG)/$(RUBY_PLATFORM)
ifdef RUBY_19_OR_LATER
RUBYINC += -I $(RUBY)/include/ruby-$(RUBY_API_VER_LONG) -I $(RUBY)/include/ruby-$(RUBY_API_VER_LONG)/$(RUBY_PLATFORM)
endif
ifeq (no, $(DYNAMIC_RUBY))
RUBYLIB = -L$(RUBY)/lib -l$(RUBY_INSTALL_NAME)
endif

endif # RUBY

# See feature.h for a list of options.
# Any other defines can be included here.
DEF_GUI=-DFEAT_GUI_W32 -DFEAT_CLIPBOARD
DEFINES=-DWIN32 -DWINVER=$(WINVER) -D_WIN32_WINNT=$(WINVER) \
	-DHAVE_PATHDEF -DFEAT_$(FEATURES) -DHAVE_STDINT_H
ifeq ($(ARCH),x86-64)
DEFINES+=-DMS_WIN64
endif

#>>>>> end of choices
###########################################################################

CFLAGS = -Iproto $(DEFINES) -pipe -march=$(ARCH) -Wall
CXXFLAGS = -std=gnu++11
WINDRES_FLAGS = --preprocessor="$(WINDRES_CC) -E -xc" -DRC_INVOKED
EXTRA_LIBS =

ifdef GETTEXT
DEFINES += -DHAVE_GETTEXT -DHAVE_LOCALE_H
GETTEXTINCLUDE = $(GETTEXT)/include
GETTEXTLIB = $(INTLPATH)
ifeq (yes, $(GETTEXT))
DEFINES += -DDYNAMIC_GETTEXT
else
ifdef DYNAMIC_GETTEXT
DEFINES += -D$(DYNAMIC_GETTEXT)
ifdef GETTEXT_DYNAMIC
DEFINES += -DGETTEXT_DYNAMIC -DGETTEXT_DLL=\"$(GETTEXT_DYNAMIC)\"
endif
endif
endif
endif

ifdef PERL
CFLAGS += -I$(PERLLIBS) -DFEAT_PERL -DPERL_IMPLICIT_CONTEXT -DPERL_IMPLICIT_SYS
ifeq (yes, $(DYNAMIC_PERL))
CFLAGS += -DDYNAMIC_PERL -DDYNAMIC_PERL_DLL=\"perl$(PERL_VER).dll\"
EXTRA_LIBS += -L$(PERLLIBS) -lperl$(PERL_VER)
endif
endif

ifdef LUA
CFLAGS += -I$(LUA)/include -I$(LUA) -DFEAT_LUA
ifeq (yes, $(DYNAMIC_LUA))
CFLAGS += -DDYNAMIC_LUA -DDYNAMIC_LUA_DLL=\"lua$(LUA_VER).dll\"
endif
endif

ifdef MZSCHEME
ifndef MZSCHEME_COLLECTS
MZSCHEME_COLLECTS=$(MZSCHEME)/collects
ifeq (yes, $(UNDER_CYGWIN))
MZSCHEME_COLLECTS:=$(shell cygpath -m $(MZSCHEME_COLLECTS) | sed -e 's/ /\\ /g')
endif
endif
CFLAGS += -I$(MZSCHEME)/include -DFEAT_MZSCHEME -DMZSCHEME_COLLECTS=\"$(MZSCHEME_COLLECTS)\"
ifeq (yes, $(DYNAMIC_MZSCHEME))
ifeq (yes, $(MZSCHEME_PRECISE_GC))
# Precise GC does not use separate dll
CFLAGS += -DDYNAMIC_MZSCHEME -DDYNAMIC_MZSCH_DLL=\"lib$(MZSCHEME_MAIN_LIB)$(MZSCHEME_VER).dll\" -DDYNAMIC_MZGC_DLL=\"lib$(MZSCHEME_MAIN_LIB)$(MZSCHEME_VER).dll\"
else
CFLAGS += -DDYNAMIC_MZSCHEME -DDYNAMIC_MZSCH_DLL=\"lib$(MZSCHEME_MAIN_LIB)$(MZSCHEME_VER).dll\" -DDYNAMIC_MZGC_DLL=\"libmzgc$(MZSCHEME_VER).dll\"
endif
endif
ifeq (yes, "$(MZSCHEME_DEBUG)")
CFLAGS += -DMZSCHEME_FORCE_GC
endif
endif

ifdef RUBY
CFLAGS += -DFEAT_RUBY $(RUBYINC)
ifeq (yes, $(DYNAMIC_RUBY))
CFLAGS += -DDYNAMIC_RUBY -DDYNAMIC_RUBY_DLL=\"$(RUBY_INSTALL_NAME).dll\"
CFLAGS += -DDYNAMIC_RUBY_VER=$(RUBY_VER)
endif
ifneq ($(findstring w64-mingw32,$(CC)),)
# A workaround for MinGW-w64
CFLAGS += -DHAVE_STRUCT_TIMESPEC -DHAVE_STRUCT_TIMEZONE
endif
endif

ifdef PYTHON
CFLAGS += -DFEAT_PYTHON
ifeq (yes, $(DYNAMIC_PYTHON))
CFLAGS += -DDYNAMIC_PYTHON -DDYNAMIC_PYTHON_DLL=\"$(DYNAMIC_PYTHON_DLL)\"
endif
endif

ifdef PYTHON3
CFLAGS += -DFEAT_PYTHON3
ifeq (yes, $(DYNAMIC_PYTHON3))
CFLAGS += -DDYNAMIC_PYTHON3 -DDYNAMIC_PYTHON3_DLL=\"$(DYNAMIC_PYTHON3_DLL)\"
endif
endif

ifdef TCL
CFLAGS += -DFEAT_TCL $(TCLINC)
ifeq (yes, $(DYNAMIC_TCL))
CFLAGS += -DDYNAMIC_TCL -DDYNAMIC_TCL_DLL=\"tcl$(TCL_VER).dll\" -DDYNAMIC_TCL_VER=\"$(TCL_VER_LONG)\"
endif
endif

ifeq ($(POSTSCRIPT),yes)
DEFINES += -DMSWINPS
endif

ifeq (yes, $(OLE))
DEFINES += -DFEAT_OLE
endif

ifeq ($(CSCOPE),yes)
DEFINES += -DFEAT_CSCOPE
endif

ifeq ($(NETBEANS),yes)
# Only allow NETBEANS for a GUI build.
ifeq (yes, $(GUI))
DEFINES += -DFEAT_NETBEANS_INTG

ifeq ($(NBDEBUG), yes)
DEFINES += -DNBDEBUG
NBDEBUG_INCL = nbdebug.h
NBDEBUG_SRC = nbdebug.c
endif
endif
endif

ifeq ($(CHANNEL),yes)
DEFINES += -DFEAT_JOB_CHANNEL
endif

# DirectWrite (DirectX)
ifeq ($(DIRECTX),yes)
# Only allow DirectWrite for a GUI build.
ifeq (yes, $(GUI))
DEFINES += -DFEAT_DIRECTX -DDYNAMIC_DIRECTX
endif
endif

# Only allow XPM for a GUI build.
ifeq (yes, $(GUI))

ifndef XPM
ifeq ($(ARCH),i386)
XPM = xpm/x86
endif
ifeq ($(ARCH),i486)
XPM = xpm/x86
endif
ifeq ($(ARCH),i586)
XPM = xpm/x86
endif
ifeq ($(ARCH),i686)
XPM = xpm/x86
endif
ifeq ($(ARCH),x86-64)
XPM = xpm/x64
endif
endif
ifdef XPM
ifneq ($(XPM),no)
CFLAGS += -DFEAT_XPM_W32 -I $(XPM)/include -I $(XPM)/../include
endif
endif

endif

ifeq ($(DEBUG),yes)
CFLAGS += -g -fstack-check
DEBUG_SUFFIX=d
else
ifeq ($(OPTIMIZE), SIZE)
CFLAGS += -Os
else
ifeq ($(OPTIMIZE), MAXSPEED)
CFLAGS += -O3
CFLAGS += -fomit-frame-pointer -freg-struct-return
else  # SPEED
CFLAGS += -O2
endif
endif
CFLAGS += -s
endif

LIB = -lkernel32 -luser32 -lgdi32 -ladvapi32 -lcomdlg32 -lcomctl32 -lversion
GUIOBJ =  $(OUTDIR)/gui.o $(OUTDIR)/gui_w32.o $(OUTDIR)/gui_beval.o $(OUTDIR)/os_w32exe.o
CUIOBJ = $(OUTDIR)/iscygpty.o
OBJ = \
	$(OUTDIR)/arabic.o \
	$(OUTDIR)/blowfish.o \
	$(OUTDIR)/buffer.o \
	$(OUTDIR)/charset.o \
	$(OUTDIR)/crypt.o \
	$(OUTDIR)/crypt_zip.o \
	$(OUTDIR)/dict.o \
	$(OUTDIR)/diff.o \
	$(OUTDIR)/digraph.o \
	$(OUTDIR)/edit.o \
	$(OUTDIR)/eval.o \
	$(OUTDIR)/evalfunc.o \
	$(OUTDIR)/ex_cmds.o \
	$(OUTDIR)/ex_cmds2.o \
	$(OUTDIR)/ex_docmd.o \
	$(OUTDIR)/ex_eval.o \
	$(OUTDIR)/ex_getln.o \
	$(OUTDIR)/farsi.o \
	$(OUTDIR)/fileio.o \
	$(OUTDIR)/fold.o \
	$(OUTDIR)/getchar.o \
	$(OUTDIR)/hardcopy.o \
	$(OUTDIR)/hashtab.o \
	$(OUTDIR)/json.o \
	$(OUTDIR)/list.o \
	$(OUTDIR)/main.o \
	$(OUTDIR)/mark.o \
	$(OUTDIR)/memfile.o \
	$(OUTDIR)/memline.o \
	$(OUTDIR)/menu.o \
	$(OUTDIR)/message.o \
	$(OUTDIR)/misc1.o \
	$(OUTDIR)/misc2.o \
	$(OUTDIR)/move.o \
	$(OUTDIR)/mbyte.o \
	$(OUTDIR)/normal.o \
	$(OUTDIR)/ops.o \
	$(OUTDIR)/option.o \
	$(OUTDIR)/os_win32.o \
	$(OUTDIR)/os_mswin.o \
	$(OUTDIR)/winclip.o \
	$(OUTDIR)/pathdef.o \
	$(OUTDIR)/popupmnu.o \
	$(OUTDIR)/quickfix.o \
	$(OUTDIR)/regexp.o \
	$(OUTDIR)/screen.o \
	$(OUTDIR)/search.o \
	$(OUTDIR)/sha256.o \
	$(OUTDIR)/spell.o \
	$(OUTDIR)/spellfile.o \
	$(OUTDIR)/syntax.o \
	$(OUTDIR)/tag.o \
	$(OUTDIR)/term.o \
	$(OUTDIR)/ui.o \
	$(OUTDIR)/undo.o \
	$(OUTDIR)/userfunc.o \
	$(OUTDIR)/version.o \
	$(OUTDIR)/vimrc.o \
	$(OUTDIR)/window.o

ifdef PERL
OBJ += $(OUTDIR)/if_perl.o
endif
ifdef LUA
OBJ += $(OUTDIR)/if_lua.o
endif
ifdef MZSCHEME
OBJ += $(OUTDIR)/if_mzsch.o
MZSCHEME_INCL = if_mzsch.h
ifeq (yes,$(MZSCHEME_GENERATE_BASE))
CFLAGS += -DINCLUDE_MZSCHEME_BASE
MZ_EXTRA_DEP += mzscheme_base.c
endif
ifeq (yes,$(MZSCHEME_PRECISE_GC))
CFLAGS += -DMZ_PRECISE_GC
endif
endif
ifdef PYTHON
OBJ += $(OUTDIR)/if_python.o
endif
ifdef PYTHON3
OBJ += $(OUTDIR)/if_python3.o
endif
ifdef RUBY
OBJ += $(OUTDIR)/if_ruby.o
endif
ifdef TCL
OBJ += $(OUTDIR)/if_tcl.o
endif
ifeq ($(CSCOPE),yes)
OBJ += $(OUTDIR)/if_cscope.o
endif

ifeq ($(NETBEANS),yes)
ifneq ($(CHANNEL),yes)
# Cannot use Netbeans without CHANNEL
NETBEANS=no
else
ifneq (yes, $(GUI))
# Cannot use Netbeans without GUI.
NETBEANS=no
else
OBJ += $(OUTDIR)/netbeans.o
endif
endif
endif

ifeq ($(CHANNEL),yes)
OBJ += $(OUTDIR)/channel.o
LIB += -lwsock32
endif

ifeq ($(DIRECTX),yes)
# Only allow DIRECTX for a GUI build.
ifeq (yes, $(GUI))
OBJ += $(OUTDIR)/gui_dwrite.o
LIB += -ld2d1 -ldwrite
USE_STDCPLUS = yes
endif
endif
ifneq ($(XPM),no)
# Only allow XPM for a GUI build.
ifeq (yes, $(GUI))
OBJ += $(OUTDIR)/xpm_w32.o
# You'll need libXpm.a from http://gnuwin32.sf.net
LIB += -L$(XPM)/lib -lXpm
endif
endif


ifdef MZSCHEME
MZSCHEME_SUFFIX = Z
endif

ifeq ($(GUI),yes)
TARGET := gvim$(DEBUG_SUFFIX).exe
DEFINES += $(DEF_GUI)
OBJ += $(GUIOBJ)
LFLAGS += -mwindows
OUTDIR = gobj$(DEBUG_SUFFIX)$(MZSCHEME_SUFFIX)$(ARCH)
else
OBJ += $(CUIOBJ)
TARGET := vim$(DEBUG_SUFFIX).exe
OUTDIR = obj$(DEBUG_SUFFIX)$(MZSCHEME_SUFFIX)$(ARCH)
endif

ifdef GETTEXT
ifneq (yes, $(GETTEXT))
CFLAGS += -I$(GETTEXTINCLUDE)
ifndef STATIC_GETTEXT
LIB += -L$(GETTEXTLIB) -l$(INTLLIB)
ifeq (USE_SAFE_GETTEXT_DLL, $(DYNAMIC_GETTEXT))
OBJ+=$(SAFE_GETTEXT_DLL_OBJ)
endif
else
LIB += -L$(GETTEXTLIB) -lintl
endif
endif
endif

ifdef PERL
ifeq (no, $(DYNAMIC_PERL))
LIB += -L$(PERLLIBS) -lperl$(PERL_VER)
endif
endif

ifdef TCL
LIB += -L$(TCL)/lib
ifeq (yes, $(DYNAMIC_TCL))
LIB += -ltclstub$(TCL_VER)
else
LIB += -ltcl$(TCL_VER)
endif
endif

ifeq (yes, $(OLE))
LIB += -loleaut32
OBJ += $(OUTDIR)/if_ole.o
USE_STDCPLUS = yes
endif

ifeq (yes, $(MBYTE))
DEFINES += -DFEAT_MBYTE
endif

ifeq (yes, $(IME))
DEFINES += -DFEAT_MBYTE_IME
ifeq (yes, $(DYNAMIC_IME))
DEFINES += -DDYNAMIC_IME
else
LIB += -limm32
endif
endif

ifdef ICONV
ifneq (yes, $(ICONV))
LIB += -L$(ICONV)
CFLAGS += -I$(ICONV)
endif
DEFINES+=-DDYNAMIC_ICONV
endif

ifeq (yes, $(USE_STDCPLUS))
ifeq (yes, $(STATIC_STDCPLUS))
LIB += -Wl,-Bstatic -lstdc++ -Wl,-Bdynamic
else
LIB += -lstdc++
endif
endif

ifeq (yes, $(STATIC_WINPTHREAD))
LIB += -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic
endif

all: $(TARGET) vimrun.exe xxd/xxd.exe install.exe uninstal.exe GvimExt/gvimext.dll

vimrun.exe: vimrun.c
	$(CC) $(CFLAGS) -o vimrun.exe vimrun.c $(LIB)

install.exe: dosinst.c
	$(CC) $(CFLAGS) -o install.exe dosinst.c $(LIB) -lole32 -luuid

uninstal.exe: uninstal.c
	$(CC) $(CFLAGS) -o uninstal.exe uninstal.c $(LIB)

$(TARGET): $(OUTDIR) $(OBJ)
	$(CC) $(CFLAGS) $(LFLAGS) -o $@ $(OBJ) $(LIB) -lole32 -luuid $(LUA_LIB) $(MZSCHEME_LIBDIR) $(MZSCHEME_LIB) $(PYTHONLIB) $(PYTHON3LIB) $(RUBYLIB)

upx: exes
	upx gvim.exe
	upx vim.exe

mpress: exes
	mpress gvim.exe
	mpress vim.exe

xxd/xxd.exe: xxd/xxd.c
	$(MAKE) -C xxd -f Make_ming.mak CC='$(CC)'

GvimExt/gvimext.dll: GvimExt/gvimext.cpp GvimExt/gvimext.rc GvimExt/gvimext.h
	$(MAKE) -C GvimExt -f Make_ming.mak CROSS=$(CROSS) CROSS_COMPILE=$(CROSS_COMPILE) CXX='$(CXX)' STATIC_STDCPLUS=$(STATIC_STDCPLUS)

clean:
	-$(DEL) $(OUTDIR)$(DIRSLASH)*.o
	-$(DEL) $(OUTDIR)$(DIRSLASH)*.res
	-rmdir $(OUTDIR)
	-$(DEL) *.exe
	-$(DEL) pathdef.c
ifdef PERL
	-$(DEL) if_perl.c
endif
ifdef MZSCHEME
	-$(DEL) mzscheme_base.c
endif
	$(MAKE) -C GvimExt -f Make_ming.mak clean
	$(MAKE) -C xxd -f Make_ming.mak clean

###########################################################################
INCL = vim.h feature.h os_win32.h os_dos.h ascii.h keymap.h term.h macros.h \
	structs.h regexp.h option.h ex_cmds.h proto.h globals.h farsi.h \
	gui.h
CUI_INCL = iscygpty.h

$(OUTDIR)/if_python.o : if_python.c if_py_both.h $(INCL)
	$(CC) -c $(CFLAGS) $(PYTHONINC) $(PYTHON_HOME_DEF) $< -o $@

$(OUTDIR)/if_python3.o : if_python3.c if_py_both.h $(INCL)
	$(CC) -c $(CFLAGS) $(PYTHON3INC) $(PYTHON3_HOME_DEF) $< -o $@

$(OUTDIR)/%.o : %.c $(INCL)
	$(CC) -c $(CFLAGS) $< -o $@

$(OUTDIR)/vimrc.o: vim.rc version.h gui_w32_rc.h
	$(WINDRES) $(WINDRES_FLAGS) $(DEFINES) \
	    --input-format=rc --output-format=coff -i vim.rc -o $@

$(OUTDIR):
	$(MKDIR) $(OUTDIR)

$(OUTDIR)/ex_docmd.o:	ex_docmd.c $(INCL) ex_cmds.h
	$(CC) -c $(CFLAGS) ex_docmd.c -o $(OUTDIR)/ex_docmd.o

$(OUTDIR)/ex_eval.o:	ex_eval.c $(INCL) ex_cmds.h
	$(CC) -c $(CFLAGS) ex_eval.c -o $(OUTDIR)/ex_eval.o

$(OUTDIR)/gui_w32.o:	gui_w32.c $(INCL)
	$(CC) -c $(CFLAGS) gui_w32.c -o $(OUTDIR)/gui_w32.o

$(OUTDIR)/gui_dwrite.o:	gui_dwrite.cpp $(INCL) gui_dwrite.h
	$(CC) -c $(CFLAGS) $(CXXFLAGS) gui_dwrite.cpp -o $(OUTDIR)/gui_dwrite.o

$(OUTDIR)/if_cscope.o:	if_cscope.c $(INCL) if_cscope.h
	$(CC) -c $(CFLAGS) if_cscope.c -o $(OUTDIR)/if_cscope.o

# Remove -D__IID_DEFINED__ for newer versions of the w32api
$(OUTDIR)/if_ole.o: if_ole.cpp $(INCL)
	$(CC) $(CFLAGS) $(CXXFLAGS) -c -o $(OUTDIR)/if_ole.o if_ole.cpp

$(OUTDIR)/if_ruby.o: if_ruby.c $(INCL)
ifeq (16, $(RUBY))
	$(CC) $(CFLAGS) -U_WIN32 -c -o $(OUTDIR)/if_ruby.o if_ruby.c
endif

if_perl.c: if_perl.xs typemap
	$(XSUBPP) -prototypes -typemap \
	     $(PERLTYPEMAP) if_perl.xs > $@

$(OUTDIR)/iscygpty.o:	iscygpty.c $(CUI_INCL)
	$(CC) -c $(CFLAGS) iscygpty.c -o $(OUTDIR)/iscygpty.o -U_WIN32_WINNT -D_WIN32_WINNT=0x0600 -DUSE_DYNFILEID -DENABLE_STUB_IMPL

$(OUTDIR)/main.o:		main.c $(INCL) $(CUI_INCL)
	$(CC) -c $(CFLAGS) main.c -o $(OUTDIR)/main.o

$(OUTDIR)/netbeans.o:	netbeans.c $(INCL) $(NBDEBUG_INCL) $(NBDEBUG_SRC)
	$(CC) -c $(CFLAGS) netbeans.c -o $(OUTDIR)/netbeans.o

$(OUTDIR)/channel.o:	channel.c $(INCL)
	$(CC) -c $(CFLAGS) channel.c -o $(OUTDIR)/channel.o

$(OUTDIR)/regexp.o:		regexp.c regexp_nfa.c $(INCL)
	$(CC) -c $(CFLAGS) regexp.c -o $(OUTDIR)/regexp.o

$(OUTDIR)/if_mzsch.o:	if_mzsch.c $(INCL) if_mzsch.h $(MZ_EXTRA_DEP)
	$(CC) -c $(CFLAGS) if_mzsch.c -o $(OUTDIR)/if_mzsch.o

mzscheme_base.c:
	$(MZSCHEME)/mzc --c-mods mzscheme_base.c ++lib scheme/base

pathdef.c: $(INCL)
ifneq (sh.exe, $(SHELL))
	@echo creating pathdef.c
	@echo '/* pathdef.c */' > pathdef.c
	@echo '#include "vim.h"' >> pathdef.c
	@echo 'char_u *default_vim_dir = (char_u *)"$(VIMRCLOC)";' >> pathdef.c
	@echo 'char_u *default_vimruntime_dir = (char_u *)"$(VIMRUNTIMEDIR)";' >> pathdef.c
	@echo 'char_u *all_cflags = (char_u *)"$(CC) $(CFLAGS)";' >> pathdef.c
	@echo 'char_u *all_lflags = (char_u *)"$(CC) $(CFLAGS) $(LFLAGS) -o $(TARGET) $(LIB) -lole32 -luuid $(LUA_LIB) $(MZSCHEME_LIBDIR) $(MZSCHEME_LIB) $(PYTHONLIB) $(PYTHON3LIB) $(RUBYLIB)";' >> pathdef.c
	@echo 'char_u *compiled_user = (char_u *)"$(USERNAME)";' >> pathdef.c
	@echo 'char_u *compiled_sys = (char_u *)"$(USERDOMAIN)";' >> pathdef.c
else
	@echo creating pathdef.c
	@echo /* pathdef.c */ > pathdef.c
	@echo #include "vim.h" >> pathdef.c
	@echo char_u *default_vim_dir = (char_u *)"$(VIMRCLOC)"; >> pathdef.c
	@echo char_u *default_vimruntime_dir = (char_u *)"$(VIMRUNTIMEDIR)"; >> pathdef.c
	@echo char_u *all_cflags = (char_u *)"$(CC) $(CFLAGS)"; >> pathdef.c
	@echo char_u *all_lflags = (char_u *)"$(CC) $(CFLAGS) $(LFLAGS) -o $(TARGET) $(LIB) -lole32 -luuid $(LUA_LIB) $(MZSCHEME_LIBDIR) $(MZSCHEME_LIB) $(PYTHONLIB) $(PYTHON3LIB) $(RUBYLIB)"; >> pathdef.c
	@echo char_u *compiled_user = (char_u *)"$(USERNAME)"; >> pathdef.c
	@echo char_u *compiled_sys = (char_u *)"$(USERDOMAIN)"; >> pathdef.c
endif
