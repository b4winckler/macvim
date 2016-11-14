#
# Makefile for Vim on OpenVMS
#
# Maintainer:   Zoltan Arpadffy <arpadffy@polarhome.com>
# Last change:  2016 Nov 04
#
# This has script been tested on VMS 6.2 to 8.2 on DEC Alpha, VAX and IA64
# with MMS and MMK
#
# The following could be built:
#	vim.exe:	standard (terminal, GUI/Motif, GUI/GTK)
#	dvim.exe:	debug
#
# Edit the lines in the Configuration section below for fine tuning.
#
# To build:    mms/descrip=Make_vms.mms /ignore=warning
# To clean up: mms/descrip=Make_vms.mms clean
#
# Hints and detailed description could be found in INSTALLVMS.TXT file.
#
######################################################################
# Configuration section.
######################################################################

# Compiler selection.
# Comment out if you use the VAXC compiler
DECC = YES

# Build model selection
# TINY   - Almost no features enabled, not even multiple windows
# SMALL  - Few features enabled, as basic as possible
# NORMAL - A default selection of features enabled
# BIG    - Many features enabled, as rich as possible. (default)
# HUGE   - All possible features enabled.
# Please select one of these alternatives above.
MODEL = HUGE

# GUI or terminal mode executable.
# Comment out if you want just the character terminal mode only.
# GUI with Motif
GUI = YES

# GUI with GTK
# If you have GTK installed you might want to enable this option.
# NOTE: you will need to properly define GTK_DIR below
# GTK = YES

# GUI/Motif with XPM
# If you have XPM installed you might want to build Motif version with toolbar
# XPM = YES

# Comment out if you want the compiler version with :ver command.
# NOTE: This part can make some complications if you're using some
# predefined symbols/flags for your compiler. If does, just leave behind
# the comment variable CCVER.
CCVER = YES

# Uncomment if want a debug version. Resulting executable is DVIM.EXE
# Development purpose only! Normally, it should not be defined. !!!
# DEBUG = YES 

# Languages support for Perl, Python, TCL etc.
# If you don't need it really, leave them behind the comment.
# You will need related libraries, include files etc.
# VIM_TCL    = YES
# VIM_PERL   = YES
# VIM_PYTHON = YES
# VIM_RUBY   = YES

# X Input Method.  For entering special languages like chinese and
# Japanese. Please define just one: VIM_XIM or VIM_HANGULIN
# If you don't need it really, leave it behind the comment.
# VIM_XIM = YES

# Internal Hangul input method. GUI only.
# If you don't need it really, leave it behind the comment.
# VIM_HANGULIN = YES

# Allow any white space to separate the fields in a tags file
# When not defined, only a TAB is allowed.
# VIM_TAG_ANYWHITE = YES

# Allow FEATURE_MZSCHEME
# VIM_MZSCHEME = YES

# Use ICONV
# VIM_ICONV  = YES

######################################################################
# Directory, library and include files configuration section.
# Normally you need not to change anything below. !
# These may need to be defined if things are not in standard locations
#
# You can find some explanation in INSTALLVMS.TXT
######################################################################

# Compiler setup

.IFDEF MMSVAX
.IFDEF DECC	     # VAX with DECC
CC_DEF  = cc # /decc # some versions require /decc switch but when it is not required /ver might fail
PREFIX  = /prefix=all
OPTIMIZE= /noopt     # do not optimize on VAX. The compiler has hard time with crypto functions
.ELSE		     # VAX with VAXC
CC_DEF	= cc
PREFIX	=
OPTIMIZE= /noopt
CCVER	=
.ENDIF
.ELSE		     # AXP and IA64 with DECC
CC_DEF  = cc
PREFIX  = /prefix=all
OPTIMIZE= /opt
.ENDIF


LD_DEF  = link
C_INC   = [.proto]

.IFDEF DEBUG
DEBUG_DEF = ,"DEBUG"
TARGET    = dvim.exe
CFLAGS    = /debug/noopt$(PREFIX)
LDFLAGS   = /debug
.ELSE
TARGET    = vim.exe
CFLAGS    = $(OPTIMIZE)$(PREFIX)
LDFLAGS   =
.ENDIF

# Predefined VIM directories
# Please, use $VIM and $VIMRUNTIME logicals instead
VIMLOC  = ""
VIMRUN  = ""

CONFIG_H = os_vms_conf.h

# GTK or XPM but not both
.IFDEF GTK
.IFDEF GUI
.ELSE
GUI = YES
.ENDIF
.IFDEF XPM
XPM = ""
.ENDIF
.ENDIF

.IFDEF XPM
.IFDEF GUI
.ELSE
GUI = YES
.ENDIF
.IFDEF GTK
GTK = ""
.ENDIF
.ENDIF

.IFDEF GUI
# X/Motif/GTK executable  (also works in terminal mode )

.IFDEF GTK
# NOTE: you need to set up your GTK_DIR (GTK root directory), because it is
# unique on every system - logicals are not accepted
# please note: directory should end with . in order to /trans=conc work
# This value for GTK_DIR is an example.
GTK_DIR  = $1$DGA104:[USERS.ZAY.WORK.GTK1210.]
DEFS     = "HAVE_CONFIG_H","FEAT_GUI_GTK"
LIBS     = ,OS_VMS_GTK.OPT/OPT
GUI_FLAG = /name=(as_is,short)/float=ieee/ieee=denorm
GUI_SRC  = gui.c gui_gtk.c gui_gtk_f.c gui_gtk_x11.c gui_beval.c pty.c
GUI_OBJ  = gui.obj gui_gtk.obj gui_gtk_f.obj gui_gtk_x11.obj gui_beval.obj pty.obj
GUI_INC  = ,"/gtk_root/gtk","/gtk_root/glib"
# GUI_INC_VER is used just for :ver information
# this string should escape from C and DCL in the same time
GUI_INC_VER= ,\""/gtk_root/gtk\"",\""/gtk_root/glib\""
.ELSE
MOTIF	 = YES
.IFDEF XPM
DEFS     = "HAVE_CONFIG_H","FEAT_GUI_MOTIF","HAVE_XPM"
.ELSE
DEFS     = "HAVE_CONFIG_H","FEAT_GUI_MOTIF"
.ENDIF
LIBS     = ,OS_VMS_MOTIF.OPT/OPT
GUI_FLAG =
GUI_SRC  = gui.c gui_motif.c gui_x11.c gui_beval.c gui_xmdlg.c gui_xmebw.c
GUI_OBJ  = gui.obj gui_motif.obj gui_x11.obj gui_beval.obj gui_xmdlg.obj gui_xmebw.obj
GUI_INC  =
.ENDIF

# You need to define these variables if you do not have DECW files
# at standard location
GUI_INC_DIR = ,decw$include:
# GUI_LIB_DIR = ,sys$library:

.ELSE
# Character terminal only executable
DEFS	 = "HAVE_CONFIG_H"
LIBS	 =
.ENDIF

.IFDEF VIM_PERL
# Perl related setup.
PERL	 = perl
PERL_DEF = ,"FEAT_PERL"
PERL_SRC = if_perlsfio.c if_perl.xs
PERL_OBJ = if_perlsfio.obj if_perl.obj
PERL_LIB = ,OS_VMS_PERL.OPT/OPT
PERL_INC = ,dka0:[perlbuild.perl.lib.vms_axp.5_6_1.core]
.ENDIF

.IFDEF VIM_PYTHON
# Python related setup.
PYTHON_DEF = ,"FEAT_PYTHON"
PYTHON_SRC = if_python.c
PYTHON_OBJ = if_python.obj
PYTHON_LIB = ,OS_VMS_PYTHON.OPT/OPT
PYTHON_INC = ,PYTHON_INCLUDE
.ENDIF

.IFDEF VIM_TCL
# TCL related setup.
TCL_DEF = ,"FEAT_TCL"
TCL_SRC = if_tcl.c
TCL_OBJ = if_tcl.obj
TCL_LIB = ,OS_VMS_TCL.OPT/OPT
TCL_INC = ,dka0:[tcl80.generic]
.ENDIF

.IFDEF VIM_RUBY
# RUBY related setup.
RUBY_DEF = ,"FEAT_RUBY"
RUBY_SRC = if_ruby.c
RUBY_OBJ = if_ruby.obj
RUBY_LIB = ,OS_VMS_RUBY.OPT/OPT
RUBY_INC =
.ENDIF

.IFDEF VIM_XIM
# XIM related setup.
.IFDEF GUI
XIM_DEF = ,"FEAT_XIM"
.ENDIF
.ENDIF

.IFDEF VIM_HANGULIN
# HANGULIN related setup.
.IFDEF GUI
HANGULIN_DEF = ,"FEAT_HANGULIN"
HANGULIN_SRC = hangulin.c
HANGULIN_OBJ = hangulin.obj
.ENDIF
.ENDIF

.IFDEF VIM_TAG_ANYWHITE
# TAG_ANYWHITE related setup.
TAG_DEF = ,"FEAT_TAG_ANYWHITE"
.ENDIF

.IFDEF VIM_MZSCHEME
# MZSCHEME related setup
MZSCH_DEF = ,"FEAT_MZSCHEME"
MZSCH_SRC = if_mzsch.c 
MZSCH_OBJ = if_mzsch.obj
.ENDIF

.IFDEF VIM_ICONV
# ICONV related setup
ICONV_DEF = ,"USE_ICONV"
.ENDIF

######################################################################
# End of configuration section.
# Please, do not change anything below without programming experience.
######################################################################

MODEL_DEF = "FEAT_$(MODEL)",

# These go into pathdef.c
VIMUSER = "''F$EDIT(F$GETJPI(" ","USERNAME"),"TRIM")'"
VIMHOST = "''F$TRNLNM("SYS$NODE")'''F$TRNLNM("UCX$INET_HOST")'.''F$TRNLNM("UCX$INET_DOMAIN")'"

.SUFFIXES : .obj .c

ALL_CFLAGS = /def=($(MODEL_DEF)$(DEFS)$(DEBUG_DEF)$(PERL_DEF)$(PYTHON_DEF) -
 $(TCL_DEF)$(RUBY_DEF)$(XIM_DEF)$(HANGULIN_DEF)$(TAG_DEF)$(MZSCH_DEF)$(ICONV_DEF)) -
 $(CFLAGS)$(GUI_FLAG) -
 /include=($(C_INC)$(GUI_INC_DIR)$(GUI_INC)$(PERL_INC)$(PYTHON_INC)$(TCL_INC))

# CFLAGS displayed in :ver information
# It is specially formated for correct display of unix like includes
# as $(GUI_INC) - replaced with $(GUI_INC_VER)
# Otherwise should not be any other difference.
ALL_CFLAGS_VER = /def=($(MODEL_DEF)$(DEFS)$(DEBUG_DEF)$(PERL_DEF)$(PYTHON_DEF) -
 $(TCL_DEF)$(RUBY_DEF)$(XIM_DEF)$(HANGULIN_DEF)$(TAG_DEF)$(MZSCH_DEF)$(ICONV_DEF)) -
 $(CFLAGS)$(GUI_FLAG) -
 /include=($(C_INC)$(GUI_INC_DIR)$(GUI_INC_VER)$(PERL_INC)$(PYTHON_INC)$(TCL_INC))

ALL_LIBS = $(LIBS) $(GUI_LIB_DIR) $(GUI_LIB) \
	   $(PERL_LIB) $(PYTHON_LIB) $(TCL_LIB) $(RUBY_LIB)

SRC =	arabic.c blowfish.c buffer.c charset.c crypt.c crypt_zip.c dict.c diff.c digraph.c edit.c eval.c evalfunc.c \
	ex_cmds.c ex_cmds2.c ex_docmd.c ex_eval.c ex_getln.c if_cscope.c if_xcmdsrv.c farsi.c fileio.c fold.c getchar.c \
	hardcopy.c hashtab.c json.c list.c main.c mark.c menu.c mbyte.c memfile.c memline.c message.c misc1.c \
	misc2.c move.c normal.c ops.c option.c popupmnu.c quickfix.c regexp.c search.c sha256.c\
	spell.c spellfile.c syntax.c tag.c term.c termlib.c ui.c undo.c userfunc.c version.c screen.c \
	window.c os_unix.c os_vms.c pathdef.c \
	$(GUI_SRC) $(PERL_SRC) $(PYTHON_SRC) $(TCL_SRC) \
	$(RUBY_SRC) $(HANGULIN_SRC) $(MZSCH_SRC)

OBJ = 	arabic.obj blowfish.obj buffer.obj charset.obj crypt.obj crypt_zip.obj dict.obj diff.obj digraph.obj edit.obj eval.obj \
	evalfunc.obj ex_cmds.obj ex_cmds2.obj ex_docmd.obj ex_eval.obj ex_getln.obj if_cscope.obj \
	if_xcmdsrv.obj farsi.obj fileio.obj fold.obj getchar.obj hardcopy.obj hashtab.obj json.obj list.obj main.obj mark.obj \
	menu.obj memfile.obj memline.obj message.obj misc1.obj misc2.obj \
	move.obj mbyte.obj normal.obj ops.obj option.obj popupmnu.obj quickfix.obj \
	regexp.obj search.obj sha256.obj spell.obj spellfile.obj syntax.obj tag.obj term.obj termlib.obj \
	ui.obj undo.obj userfunc.obj screen.obj version.obj window.obj os_unix.obj \
	os_vms.obj pathdef.obj if_mzsch.obj\
	$(GUI_OBJ) $(PERL_OBJ) $(PYTHON_OBJ) $(TCL_OBJ) \
	$(RUBY_OBJ) $(HANGULIN_OBJ) $(MZSCH_OBJ)

# Default target is making the executable
all : [.auto]config.h mmk_compat motif_env gtk_env perl_env python_env tcl_env ruby_env $(TARGET)
	! $@

[.auto]config.h : $(CONFIG_H)
	copy/nolog $(CONFIG_H) [.auto]config.h

mmk_compat :
	-@ open/write pd pathdef.c
	-@ write pd "/* Empty file to satisfy MMK depend.  */"
	-@ write pd "/* It will be overwritten later on... */"
	-@ close pd
clean :
	-@ if "''F$SEARCH("*.exe")'" .NES. "" then delete/noconfirm/nolog *.exe;*
	-@ if "''F$SEARCH("*.obj")'" .NES. "" then delete/noconfirm/nolog *.obj;*
	-@ if "''F$SEARCH("[.auto]config.h")'" .NES. "" then delete/noconfirm/nolog [.auto]config.h;*
	-@ if "''F$SEARCH("pathdef.c")'" .NES. "" then delete/noconfirm/nolog pathdef.c;*
	-@ if "''F$SEARCH("if_perl.c")'" .NES. "" then delete/noconfirm/nolog if_perl.c;*
	-@ if "''F$SEARCH("*.opt")'" .NES. "" then delete/noconfirm/nolog *.opt;*

# Link the target
$(TARGET) : $(OBJ)
	$(LD_DEF) $(LDFLAGS) /exe=$(TARGET) $+ $(ALL_LIBS)

.c.obj :
	$(CC_DEF) $(ALL_CFLAGS) $<

pathdef.c : check_ccver $(CONFIG_H)
	-@ write sys$output "creating PATHDEF.C file."
	-@ open/write pd pathdef.c
	-@ write pd "/* pathdef.c -- DO NOT EDIT! */"
	-@ write pd "/* This file is automatically created by MAKE_VMS.MMS"
	-@ write pd " * Change the file MAKE_VMS.MMS Only. */"
	-@ write pd "typedef unsigned char   char_u;"
	-@ write pd "char_u *default_vim_dir = (char_u *)"$(VIMLOC)";"
	-@ write pd "char_u *default_vimruntime_dir = (char_u *)"$(VIMRUN)";"
	-@ write pd "char_u *all_cflags = (char_u *)""$(CC_DEF)$(ALL_CFLAGS_VER)"";"
	-@ write pd "char_u *all_lflags = (char_u *)""$(LD_DEF)$(LDFLAGS) /exe=$(TARGET) *.OBJ $(ALL_LIBS)"";"
	-@ write pd "char_u *compiler_version = (char_u *) ""''CC_VER'"";"
	-@ write pd "char_u *compiled_user = (char_u *) "$(VIMUSER)";"
	-@ write pd "char_u *compiled_sys  = (char_u *) "$(VIMHOST)";"
	-@ write pd "char_u *compiled_arch = (char_u *) ""$(MMSARCH_NAME)"";"
	-@ close pd

if_perl.c : if_perl.xs
	-@ $(PERL) PERL_ROOT:[LIB.ExtUtils]xsubpp -prototypes -typemap -
 PERL_ROOT:[LIB.ExtUtils]typemap if_perl.xs >> $@

make_vms.mms :
	-@ write sys$output "The name of the makefile MUST be <MAKE_VMS.MMS> !!!"

.IFDEF CCVER
# This part can make some complications if you're using some predefined
# symbols/flags for your compiler. If does, just comment out CCVER variable
check_ccver :
	-@ define sys$output cc_ver.tmp
	-@ $(CC_DEF)/version
	-@ deassign sys$output
	-@ open/read file cc_ver.tmp
	-@ read file CC_VER
	-@ close file
	-@ delete/noconfirm/nolog cc_ver.tmp.*
.ELSE
check_ccver :
	-@ !
.ENDIF

.IFDEF MOTIF
motif_env :
.IFDEF XPM
	-@ write sys$output "using DECW/Motif/XPM environment."
.ELSE
	-@ write sys$output "using DECW/Motif environment."
.ENDIF
	-@ write sys$output "creating OS_VMS_MOTIF.OPT file."
	-@ open/write opt_file OS_VMS_MOTIF.OPT
	-@ write opt_file "sys$share:decw$xmlibshr12.exe/share,-"
	-@ write opt_file "sys$share:decw$xtlibshrr5.exe/share,-"
	-@ write opt_file "sys$share:decw$xlibshr.exe/share"
	-@ close opt_file
.ELSE
motif_env :
	-@ !
.ENDIF


.IFDEF GTK
gtk_env :
	-@ write sys$output "using GTK environment:"
	-@ define/nolog gtk_root /trans=conc $(GTK_DIR)
	-@ show logical gtk_root
	-@ write sys$output "    include path: "$(GUI_INC)""
	-@ write sys$output "creating OS_VMS_GTK.OPT file."
	-@ open/write opt_file OS_VMS_GTK.OPT
	-@ write opt_file "gtk_root:[glib]libglib.exe /share,-"
	-@ write opt_file "gtk_root:[glib.gmodule]libgmodule.exe /share,-"
	-@ write opt_file "gtk_root:[gtk.gdk]libgdk.exe /share,-"
	-@ write opt_file "gtk_root:[gtk.gtk]libgtk.exe /share,-"
	-@ write opt_file "sys$share:decw$xmlibshr12.exe/share,-"
	-@ write opt_file "sys$share:decw$xtlibshrr5.exe/share,-"
	-@ write opt_file "sys$share:decw$xlibshr.exe/share"
	-@ close opt_file
.ELSE
gtk_env :
	-@ !
.ENDIF

.IFDEF VIM_PERL
perl_env :
	-@ write sys$output "using PERL environment:"
	-@ show logical PERLSHR
	-@ write sys$output "    include path: ""$(PERL_INC)"""
	-@ show symbol perl
	-@ open/write pd if_perl.c
	-@ write pd "/* Empty file to satisfy MMK depend.  */"
	-@ write pd "/* It will be overwritten later on... */"
	-@ close pd
	-@ write sys$output "creating OS_VMS_PERL.OPT file."
	-@ open/write opt_file OS_VMS_PERL.OPT
	-@ write opt_file "PERLSHR /share"
	-@ close opt_file
.ELSE
perl_env :
	-@ !
.ENDIF

.IFDEF VIM_PYTHON
python_env :
	-@ write sys$output "using PYTHON environment:"
	-@ show logical PYTHON_INCLUDE
	-@ show logical PYTHON_OLB
	-@ write sys$output "creating OS_VMS_PYTHON.OPT file."
	-@ open/write opt_file OS_VMS_PYTHON.OPT
	-@ write opt_file "PYTHON_OLB:PYTHON.OLB /share"
	-@ close opt_file
.ELSE
python_env :
	-@ !
.ENDIF

.IFDEF VIM_TCL
tcl_env :
	-@ write sys$output "using TCL environment:"
	-@ show logical TCLSHR
	-@ write sys$output "    include path: ""$(TCL_INC)"""
	-@ write sys$output "creating OS_VMS_TCL.OPT file."
	-@ open/write opt_file OS_VMS_TCL.OPT
	-@ write opt_file "TCLSHR /share"
	-@ close opt_file
.ELSE
tcl_env :
	-@ !
.ENDIF

.IFDEF VIM_RUBY
ruby_env :
	-@ write sys$output "using RUBY environment:"
	-@ write sys$output "    include path: ""$(RUBY_INC)"""
	-@ write sys$output "creating OS_VMS_RUBY.OPT file."
	-@ open/write opt_file OS_VMS_RUBY.OPT
	-@ write opt_file "RUBYSHR /share"
	-@ close opt_file
.ELSE
ruby_env :
	-@ !
.ENDIF

arabic.obj : arabic.c vim.h
blowfish.obj : blowfish.c vim.h
buffer.obj : buffer.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h version.h
charset.obj : charset.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
crypt.obj : crypt.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h regexp.h gui.h \
 gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h proto.h \
 globals.h farsi.h arabic.h
crypt_zip.obj : crypt_zip.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h \
 regexp.h gui.h gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h \
 proto.h globals.h farsi.h arabic.h
dict.obj : dict.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h regexp.h gui.h \
 gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h proto.h \
 globals.h farsi.h arabic.h
diff.obj : diff.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
digraph.obj : digraph.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
edit.obj : edit.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
eval.obj : eval.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h version.h
evalfunc.obj : evalfunc.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h \
 regexp.h gui.h gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h \
 proto.h globals.h farsi.h arabic.h version.h
ex_cmds.obj : ex_cmds.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h version.h
ex_cmds2.obj : ex_cmds2.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h version.h
ex_docmd.obj : ex_docmd.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
ex_eval.obj : ex_eval.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
ex_getln.obj : ex_getln.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
farsi.obj : farsi.c vim.h
fileio.obj : fileio.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
fold.obj : fold.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
getchar.obj : getchar.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
hardcopy.obj : hardcopy.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
hashtab.obj : hashtab.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
if_cscope.obj : if_cscope.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h if_cscope.h
if_xcmdsrv.obj : if_xcmdsrv.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h version.h
if_mzsch.obj : if_mzsch.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h \
 regexp.h gui.h gui_beval.h [.proto]gui_beval.pro ex_cmds.h proto.h \
 globals.h farsi.h arabic.h if_mzsch.h 
json.obj : json.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h version.h
list.obj : list.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h regexp.h gui.h \
 gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h proto.h \
 globals.h farsi.h arabic.h
main.obj : main.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h farsi.c arabic.c
mark.obj : mark.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
memfile.obj : memfile.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
memline.obj : memline.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
menu.obj : menu.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
message.obj : message.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
misc1.obj : misc1.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h version.h
misc2.obj : misc2.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
move.obj : move.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
mbyte.obj : mbyte.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
normal.obj : normal.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
ops.obj : ops.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
option.obj : option.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
os_unix.obj : os_unix.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h os_unixx.h
os_vms.obj : os_vms.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h os_unixx.h
pathdef.obj : pathdef.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
popupmnu.obj : popupmnu.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
quickfix.obj : quickfix.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
regexp.obj : regexp.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
screen.obj : screen.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
search.obj : search.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
sha256.obj : sha256.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h regexp.h gui.h \
 gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h proto.h \
 globals.h farsi.h arabic.h
spell.obj : spell.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
spellfile.obj : spellfile.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h \
 regexp.h gui.h gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h \
 proto.h globals.h farsi.h arabic.h
syntax.obj : syntax.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
tag.obj : tag.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
term.obj : term.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
termlib.obj : termlib.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
ui.obj : ui.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
undo.obj : undo.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
userfunc.obj : userfunc.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h option.h structs.h \
 regexp.h gui.h gui_beval.h [.proto]gui_beval.pro alloc.h ex_cmds.h spell.h \
 proto.h globals.h farsi.h arabic.h
version.obj : version.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h version.h
window.obj : window.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
gui.obj : gui.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
gui_gtk.obj : gui_gtk.c gui_gtk_f.h vim.h [.auto]config.h feature.h \
 os_unix.h   ascii.h keymap.h term.h macros.h structs.h \
 regexp.h gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h \
 proto.h globals.h farsi.h arabic.h [-.pixmaps]stock_icons.h
gui_gtk_f.obj : gui_gtk_f.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h gui_gtk_f.h
gui_motif.obj : gui_motif.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h [-.pixmaps]alert.xpm [-.pixmaps]error.xpm \
 [-.pixmaps]generic.xpm [-.pixmaps]info.xpm [-.pixmaps]quest.xpm
gui_athena.obj : gui_athena.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h gui_at_sb.h
gui_gtk_x11.obj : gui_gtk_x11.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h gui_gtk_f.h [-.runtime]vim32x32.xpm \
 [-.runtime]vim16x16.xpm [-.runtime]vim48x48.xpm
gui_x11.obj : gui_x11.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h [-.runtime]vim32x32.xpm \
 [-.runtime]vim16x16.xpm [-.runtime]vim48x48.xpm [-.pixmaps]tb_new.xpm \
 [-.pixmaps]tb_open.xpm [-.pixmaps]tb_close.xpm [-.pixmaps]tb_save.xpm \
 [-.pixmaps]tb_print.xpm [-.pixmaps]tb_cut.xpm [-.pixmaps]tb_copy.xpm \
 [-.pixmaps]tb_paste.xpm [-.pixmaps]tb_find.xpm \
 [-.pixmaps]tb_find_next.xpm [-.pixmaps]tb_find_prev.xpm \
 [-.pixmaps]tb_find_help.xpm [-.pixmaps]tb_exit.xpm \
 [-.pixmaps]tb_undo.xpm [-.pixmaps]tb_redo.xpm [-.pixmaps]tb_help.xpm \
 [-.pixmaps]tb_macro.xpm [-.pixmaps]tb_make.xpm \
 [-.pixmaps]tb_save_all.xpm [-.pixmaps]tb_jump.xpm \
 [-.pixmaps]tb_ctags.xpm [-.pixmaps]tb_load_session.xpm \
 [-.pixmaps]tb_save_session.xpm [-.pixmaps]tb_new_session.xpm \
 [-.pixmaps]tb_blank.xpm [-.pixmaps]tb_maximize.xpm \
 [-.pixmaps]tb_split.xpm [-.pixmaps]tb_minimize.xpm \
 [-.pixmaps]tb_shell.xpm [-.pixmaps]tb_replace.xpm \
 [-.pixmaps]tb_vsplit.xpm [-.pixmaps]tb_maxwidth.xpm \
 [-.pixmaps]tb_minwidth.xpm
gui_at_sb.obj : gui_at_sb.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h gui_at_sb.h
gui_at_fs.obj : gui_at_fs.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h gui_at_sb.h
pty.obj : pty.c vim.h [.auto]config.h feature.h os_unix.h   \
 ascii.h keymap.h term.h macros.h structs.h regexp.h gui.h gui_beval.h \
 [.proto]gui_beval.pro option.h ex_cmds.h proto.h globals.h farsi.h \
 arabic.h
hangulin.obj : hangulin.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
if_perl.obj : [.auto]if_perl.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
if_perlsfio.obj : if_perlsfio.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
if_python.obj : if_python.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
if_tcl.obj : if_tcl.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
if_ruby.obj : if_ruby.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h version.h
gui_beval.obj : gui_beval.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h
workshop.obj : workshop.c [.auto]config.h integration.h vim.h feature.h \
 os_unix.h ascii.h keymap.h term.h macros.h structs.h \
 regexp.h gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h \
 proto.h globals.h farsi.h arabic.h version.h workshop.h
wsdebug.obj : wsdebug.c
integration.obj : integration.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h integration.h
netbeans.obj : netbeans.c vim.h [.auto]config.h feature.h os_unix.h \
 ascii.h keymap.h term.h macros.h structs.h regexp.h \
 gui.h gui_beval.h [.proto]gui_beval.pro option.h ex_cmds.h proto.h \
 globals.h farsi.h arabic.h version.h
gui_xmdlg.obj : gui_xmdlg.c
gui_xmebw.obj : gui_xmebw.c
