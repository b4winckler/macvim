/* vi:set ts=8 sts=4 sw=4:
 *
 * VIM - Vi IMproved	by Bram Moolenaar
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 */

/*
 * NextStep has a problem with configure, undefine a few things:
 */
#ifdef NeXT
# ifdef HAVE_UTIME
#  undef HAVE_UTIME
# endif
# ifdef HAVE_SYS_UTSNAME_H
#  undef HAVE_SYS_UTSNAME_H
# endif
#endif

#include <stdio.h>
#include <ctype.h>

#ifdef VAXC
# include <types.h>
# include <stat.h>
#else
# include <sys/types.h>
# include <sys/stat.h>
#endif

#ifdef HAVE_STDLIB_H
# include <stdlib.h>
#endif

#ifdef __EMX__
# define HAVE_TOTAL_MEM
#endif

#if defined(__CYGWIN__) || defined(__CYGWIN32__)
# define WIN32UNIX	/* Compiling for Win32 using Unix files. */
# define BINARY_FILE_IO

# define CASE_INSENSITIVE_FILENAME
# define USE_FNAME_CASE	/* Fix filename case differences. */
#endif

/* On AIX 4.2 there is a conflicting prototype for ioctl() in stropts.h and
 * unistd.h.  This hack should fix that (suggested by Jeff George).
 * But on AIX 4.3 it's alright (suggested by Jake Hamby). */
#if defined(FEAT_GUI) && defined(_AIX) && !defined(_AIX43) && !defined(_NO_PROTO)
# define _NO_PROTO
#endif

#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#ifdef HAVE_LIBC_H
# include <libc.h>		    /* for NeXT */
#endif

#ifdef HAVE_SYS_PARAM_H
# include <sys/param.h>	    /* defines BSD, if it's a BSD system */
#endif

/*
 * Using getcwd() is preferred, because it checks for a buffer overflow.
 * Don't use getcwd() on systems do use system("sh -c pwd").  There is an
 * autoconf check for this.
 * Use getcwd() anyway if getwd() isn't present.
 */
#if defined(HAVE_GETCWD) && !(defined(BAD_GETCWD) && defined(HAVE_GETWD))
# define USE_GETCWD
#endif

#ifndef __ARGS
    /* The AIX VisualAge cc compiler defines __EXTENDED__ instead of __STDC__
     * because it includes pre-ansi features. */
# if defined(__STDC__) || defined(__GNUC__) || defined(__EXTENDED__)
#  define __ARGS(x) x
# else
#  define __ARGS(x) ()
# endif
#endif

/* always use unlink() to remove files */
#ifndef PROTO
# ifdef VMS
#  define mch_remove(x) delete((char *)(x))
#  define vim_mkdir(x, y) mkdir((char *)(x), y)
#  ifdef VAX
#  else
#   define mch_rmdir(x) rmdir((char *)(x))
#  endif
# else
#  define vim_mkdir(x, y) mkdir((char *)(x), y)
#  define mch_rmdir(x) rmdir((char *)(x))
#  define mch_remove(x) unlink((char *)(x))
# endif
#endif

/* The number of arguments to a signal handler is configured here. */
/* It used to be a long list of almost all systems. Any system that doesn't
 * have an argument??? */
#define SIGHASARG

/* List 3 arg systems here. I guess __sgi, please test and correct me. jw. */
#if defined(__sgi) && defined(HAVE_SIGCONTEXT)
# define SIGHAS3ARGS
#endif

#ifdef SIGHASARG
# ifdef SIGHAS3ARGS
#  define SIGPROTOARG	(int, int, struct sigcontext *)
#  define SIGDEFARG(s)	(s, sig2, scont) int s, sig2; struct sigcontext *scont;
#  define SIGDUMMYARG	0, 0, (struct sigcontext *)0
# else
#  define SIGPROTOARG	(int)
#  define SIGDEFARG(s)	(s) int s UNUSED;
#  define SIGDUMMYARG	0
# endif
#else
# define SIGPROTOARG   (void)
# define SIGDEFARG(s)  ()
# define SIGDUMMYARG
#endif

#ifdef HAVE_DIRENT_H
# include <dirent.h>
# ifndef NAMLEN
#  define NAMLEN(dirent) strlen((dirent)->d_name)
# endif
#else
# define dirent direct
# define NAMLEN(dirent) (dirent)->d_namlen
# if HAVE_SYS_NDIR_H
#  include <sys/ndir.h>
# endif
# if HAVE_SYS_DIR_H
#  include <sys/dir.h>
# endif
# if HAVE_NDIR_H
#  include <ndir.h>
# endif
#endif

#if !defined(HAVE_SYS_TIME_H) || defined(TIME_WITH_SYS_TIME)
# include <time.h>	    /* on some systems time.h should not be
			       included together with sys/time.h */
#endif
#ifdef HAVE_SYS_TIME_H
# include <sys/time.h>
#endif

#include <signal.h>

#if defined(DIRSIZ) && !defined(MAXNAMLEN)
# define MAXNAMLEN DIRSIZ
#endif

#if defined(UFS_MAXNAMLEN) && !defined(MAXNAMLEN)
# define MAXNAMLEN UFS_MAXNAMLEN    /* for dynix/ptx */
#endif

#if defined(NAME_MAX) && !defined(MAXNAMLEN)
# define MAXNAMLEN NAME_MAX	    /* for Linux before .99p3 */
#endif

/*
 * Note: if MAXNAMLEN has the wrong value, you will get error messages
 *	 for not being able to open the swap file.
 */
#if !defined(MAXNAMLEN)
# define MAXNAMLEN 512		    /* for all other Unix */
#endif

#define BASENAMELEN	(MAXNAMLEN - 5)

#ifdef HAVE_PWD_H
# include <pwd.h>
#endif

#ifdef __COHERENT__
# undef __ARGS
#endif

#if (defined(HAVE_SYS_RESOURCE_H) && defined(HAVE_GETRLIMIT)) \
	|| (defined(HAVE_SYS_SYSINFO_H) && defined(HAVE_SYSINFO)) \
	|| defined(HAVE_SYSCTL) || defined(HAVE_SYSCONF)
# define HAVE_TOTAL_MEM
#endif


#ifndef PROTO

#ifdef VMS
# include <unixio.h>
# include <unixlib.h>
# include <signal.h>
# include <file.h>
# include <ssdef.h>
# include <descrip.h>
# include <libclidef.h>
# include <lnmdef.h>
# include <psldef.h>
# include <prvdef.h>
# include <dvidef.h>
# include <dcdef.h>
# include <stsdef.h>
# include <iodef.h>
# include <ttdef.h>
# include <tt2def.h>
# include <jpidef.h>
# include <rms.h>
# include <trmdef.h>
# include <string.h>
# include <starlet.h>
# include <socket.h>
# include <lib$routines.h>
# include <libdef.h>
# include <libdtdef.h>

# ifdef FEAT_GUI_GTK
#  include "gui_gtk_vms.h"
# endif
#endif

#endif /* PROTO */

#ifdef VMS
typedef struct dsc$descriptor   DESC;
#endif

/*
 * Unix system-dependent file names
 */
#ifndef SYS_VIMRC_FILE
# define SYS_VIMRC_FILE "$VIM/vimrc"
#endif
#ifndef SYS_GVIMRC_FILE
# define SYS_GVIMRC_FILE "$VIM/gvimrc"
#endif
#ifndef DFLT_HELPFILE
# define DFLT_HELPFILE	"$VIMRUNTIME/doc/help.txt"
#endif
#ifndef FILETYPE_FILE
# define FILETYPE_FILE	"filetype.vim"
#endif
#ifndef FTPLUGIN_FILE
# define FTPLUGIN_FILE	"ftplugin.vim"
#endif
#ifndef INDENT_FILE
# define INDENT_FILE	"indent.vim"
#endif
#ifndef FTOFF_FILE
# define FTOFF_FILE	"ftoff.vim"
#endif
#ifndef FTPLUGOF_FILE
# define FTPLUGOF_FILE	"ftplugof.vim"
#endif
#ifndef INDOFF_FILE
# define INDOFF_FILE	"indoff.vim"
#endif
#ifndef SYS_MENU_FILE
# define SYS_MENU_FILE	"$VIMRUNTIME/menu.vim"
#endif

#ifndef USR_EXRC_FILE
# ifdef VMS
#  define USR_EXRC_FILE "sys$login:.exrc"
# else
#  define USR_EXRC_FILE "$HOME/.exrc"
# endif
#endif

#if !defined(USR_EXRC_FILE2) && defined(OS2)
# define USR_EXRC_FILE2 "$VIM/.exrc"
#endif
#if !defined(USR_EXRC_FILE2) && defined(VMS)
# define USR_EXRC_FILE2 "sys$login:_exrc"
#endif

#ifndef USR_VIMRC_FILE
# ifdef VMS
# define USR_VIMRC_FILE  "sys$login:.vimrc"
# else
#  define USR_VIMRC_FILE "$HOME/.vimrc"
# endif
#endif


#if !defined(USR_VIMRC_FILE2)
# ifdef OS2
#  define USR_VIMRC_FILE2	"$HOME/vimfiles/vimrc"
# else
#  ifdef VMS
#   define USR_VIMRC_FILE2	"sys$login:vimfiles/vimrc"
#  else
#    define USR_VIMRC_FILE2	"~/.vim/vimrc"
#  endif
# endif
#endif

#if !defined(USR_VIMRC_FILE3) && defined(OS2)
# define USR_VIMRC_FILE3 "$VIM/.vimrc"
#endif
#if !defined(USR_VIMRC_FILE3) && defined(VMS)
# define USR_VIMRC_FILE3 "sys$login:_vimrc"
#endif

#ifndef USR_GVIMRC_FILE
# ifdef VMS
#  define USR_GVIMRC_FILE "sys$login:.gvimrc"
# else
#  define USR_GVIMRC_FILE "$HOME/.gvimrc"
# endif
#endif

#ifndef USR_GVIMRC_FILE2
# ifdef OS2
#  define USR_GVIMRC_FILE2	"$HOME/vimfiles/gvimrc"
# else
#  ifdef VMS
#   define USR_GVIMRC_FILE2	"sys$login:vimfiles/gvimrc"
#  else
#   define USR_GVIMRC_FILE2	"~/.vim/gvimrc"
#  endif
# endif
#endif

#ifdef VMS
# ifndef USR_GVIMRC_FILE3
#  define USR_GVIMRC_FILE3  "sys$login:_gvimrc"
# endif
#endif

#ifndef EVIM_FILE
# define EVIM_FILE	"$VIMRUNTIME/evim.vim"
#endif

#ifdef FEAT_VIMINFO
# ifndef VIMINFO_FILE
#  ifdef VMS
#   define VIMINFO_FILE  "sys$login:.viminfo"
#  else
#   define VIMINFO_FILE "$HOME/.viminfo"
#  endif
# endif
# if !defined(VIMINFO_FILE2) && defined(OS2)
#  define VIMINFO_FILE2 "$VIM/.viminfo"
# endif
# if !defined(VIMINFO_FILE2) && defined(VMS)
#  define VIMINFO_FILE2 "sys$login:_viminfo"
# endif
#endif

#ifndef EXRC_FILE
# define EXRC_FILE	".exrc"
#endif

#ifndef VIMRC_FILE
# define VIMRC_FILE	".vimrc"
#endif

#ifdef FEAT_GUI
# ifndef GVIMRC_FILE
#  define GVIMRC_FILE	".gvimrc"
# endif
#endif

#ifndef SYNTAX_FNAME
# define SYNTAX_FNAME	"$VIMRUNTIME/syntax/%s.vim"
#endif

#ifndef DFLT_BDIR
# ifdef OS2
#  define DFLT_BDIR     ".,c:/tmp,~/tmp,~/"
# else
#  ifdef VMS
#   define DFLT_BDIR    "./,sys$login:,tmp:"
#  else
#   define DFLT_BDIR    ".,~/tmp,~/"    /* default for 'backupdir' */
#  endif
# endif
#endif

#ifndef DFLT_DIR
# ifdef OS2
#  define DFLT_DIR      ".,~/tmp,c:/tmp,/tmp"
# else
#  ifdef VMS
#   define DFLT_DIR     "./,sys$login:,tmp:"
#  else
#   define DFLT_DIR     ".,~/tmp,/var/tmp,/tmp" /* default for 'directory' */
#  endif
# endif
#endif

#ifndef DFLT_VDIR
# ifdef OS2
#  define DFLT_VDIR     "$VIM/vimfiles/view"
# else
#  ifdef VMS
#   define DFLT_VDIR    "sys$login:vimfiles/view"
#  else
#   define DFLT_VDIR    "$HOME/.vim/view"       /* default for 'viewdir' */
#  endif
# endif
#endif

#define DFLT_ERRORFILE		"errors.err"

#ifdef OS2
# define DFLT_RUNTIMEPATH	"$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$HOME/vimfiles/after"
#else
# ifdef VMS
#  define DFLT_RUNTIMEPATH      "sys$login:vimfiles,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,sys$login:vimfiles/after"
# else
#  ifdef RUNTIME_GLOBAL
#   define DFLT_RUNTIMEPATH	"~/.vim," RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL "/after,~/.vim/after"
#  else
#   define DFLT_RUNTIMEPATH	"~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after"
#  endif
# endif
#endif

#ifdef OS2
/*
 * Try several directories to put the temp files.
 */
# define TEMPDIRNAMES	"$TMP", "$TEMP", "c:\\TMP", "c:\\TEMP", ""
# define TEMPNAMELEN	128
#else
# ifdef VMS
#  ifndef VAX
#   define VMS_TEMPNAM    /* to fix default .LIS extension */
#  endif
#  define TEMPNAME       "TMP:v?XXXXXX.txt"
#  define TEMPNAMELEN    28
# else
#  define TEMPDIRNAMES  "$TMPDIR", "/tmp", ".", "$HOME"
#  define TEMPNAMELEN    256
# endif
#endif

/* Special wildcards that need to be handled by the shell */
#define SPECIAL_WILDCHAR    "`'{"

#ifndef HAVE_OPENDIR
# define NO_EXPANDPATH
#endif

/*
 * Unix has plenty of memory, use large buffers
 */
#define CMDBUFFSIZE 1024	/* size of the command processing buffer */

/* Use the system path length if it makes sense. */
#if defined(PATH_MAX) && (PATH_MAX > 1000)
# define MAXPATHL	PATH_MAX
#else
# define MAXPATHL	1024
#endif

#define CHECK_INODE		/* used when checking if a swap file already
				    exists for a file */
#ifdef VMS  /* Use less memory because of older systems  */
# ifndef DFLT_MAXMEM
#  define DFLT_MAXMEM (2*1024)
# endif
# ifndef DFLT_MAXMEMTOT
#  define DFLT_MAXMEMTOT (5*1024)
# endif
#else
# ifndef DFLT_MAXMEM
#  define DFLT_MAXMEM	(5*1024)	 /* use up to 5 Mbyte for a buffer */
# endif
# ifndef DFLT_MAXMEMTOT
#  define DFLT_MAXMEMTOT	(10*1024)    /* use up to 10 Mbyte for Vim */
# endif
#endif

/* memmove is not present on all systems, use memmove, bcopy, memcpy or our
 * own version */
/* Some systems have (void *) arguments, some (char *). If we use (char *) it
 * works for all */
#ifdef USEMEMMOVE
# define mch_memmove(to, from, len) memmove((char *)(to), (char *)(from), len)
#else
# ifdef USEBCOPY
#  define mch_memmove(to, from, len) bcopy((char *)(from), (char *)(to), len)
# else
#  ifdef USEMEMCPY
#   define mch_memmove(to, from, len) memcpy((char *)(to), (char *)(from), len)
#  else
#   define VIM_MEMMOVE	    /* found in misc2.c */
#  endif
# endif
#endif

#ifndef PROTO
# ifdef HAVE_RENAME
#  define mch_rename(src, dst) rename(src, dst)
# else
int mch_rename __ARGS((const char *src, const char *dest));
# endif
# ifndef VMS
#  ifdef __MVS__
  /* on OS390 Unix getenv() doesn't return a pointer to persistent
   * storage -> use __getenv() */
#   define mch_getenv(x) (char_u *)__getenv((char *)(x))
#  else
#   define mch_getenv(x) (char_u *)getenv((char *)(x))
#  endif
#  define mch_setenv(name, val, x) setenv(name, val, x)
# endif
#endif

#if !defined(S_ISDIR) && defined(S_IFDIR)
# define	S_ISDIR(m) (((m) & S_IFMT) == S_IFDIR)
#endif
#if !defined(S_ISREG) && defined(S_IFREG)
# define	S_ISREG(m) (((m) & S_IFMT) == S_IFREG)
#endif
#if !defined(S_ISBLK) && defined(S_IFBLK)
# define	S_ISBLK(m) (((m) & S_IFMT) == S_IFBLK)
#endif
#if !defined(S_ISSOCK) && defined(S_IFSOCK)
# define	S_ISSOCK(m) (((m) & S_IFMT) == S_IFSOCK)
#endif
#if !defined(S_ISFIFO) && defined(S_IFIFO)
# define	S_ISFIFO(m) (((m) & S_IFMT) == S_IFIFO)
#endif
#if !defined(S_ISCHR) && defined(S_IFCHR)
# define	S_ISCHR(m) (((m) & S_IFMT) == S_IFCHR)
#endif

/* Note: Some systems need both string.h and strings.h (Savage).  However,
 * some systems can't handle both, only use string.h in that case. */
#ifdef HAVE_STRING_H
# include <string.h>
#endif
#if defined(HAVE_STRINGS_H) && !defined(NO_STRINGS_WITH_STRING_H)
# include <strings.h>
#endif

#if defined(HAVE_SETJMP_H)
# include <setjmp.h>
# ifdef HAVE_SIGSETJMP
#  define JMP_BUF sigjmp_buf
#  define SETJMP(x) sigsetjmp((x), 1)
#  define LONGJMP siglongjmp
# else
#  define JMP_BUF jmp_buf
#  define SETJMP(x) setjmp(x)
#  define LONGJMP longjmp
# endif
#endif

#ifndef HAVE_DUP
# define HAVE_DUP		/* have dup() */
#endif
#define HAVE_ST_MODE		/* have stat.st_mode */

/* We have three kinds of ACL support. */
#define HAVE_ACL (HAVE_POSIX_ACL || HAVE_SOLARIS_ACL || HAVE_AIX_ACL)
