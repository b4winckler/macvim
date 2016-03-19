TRANSLATING VIM MESSAGES

This file explains how to create and maintain po files using a number of
GnuWin packages.  You will need gettext, libiconv and libexpat.  As of
August 2010 the versions known to work are gettext 0.14.4, libiconv 1.9.2-1
and expat 2.0.1.  gettext and libiconv can be found at:

	http://gnuwin32.sourceforge.net/

expat can be found at:

	http://sourceforge.net/projects/expat/

expat will install into its own directory.  You should copy libexpat.dll into
the bin directory created from the gettext/libiconv packages.

First read the README.txt file in this directory for general remarks on
translating Vim messages.


SETUP

Set the environment variable LANGUAGE to the language code for the language
you are translating Vim messages to.  Language codes are typically two
characters and you can find a list of them at:

	http://www.geocities.com/click2speak/languages.html

Another possibility is to use the gnuwin32 port of gettext. This is
recommended especially if you use already gnuwin32 tools to gunzip, bunzip,
patch etc. these files. You find the gnuwin32 version of gettext here:

        http://gnuwin32.sourceforge.net/packages/gettext.htm

Yet another very strait forward way is to get the sources of gettext from

        http://www.gnu.org/software/gettext/gettext.html

and build your own version of these tools. The documentation states that this
should be possible with MSVC4.0, MSVC5.0, MSVC6.0 or MSVC7.0, but you can
build it even successfully with MSVC8.0.

The LANGUAGE environment variable can be set from the command line, by adding
a line to your autoexec.bat file, or by defining a user variable from the
Advanced tab in the System control panel.

Next, edit Make_mvc.mak so that GETTEXT_PATH points the binary directory of
the installation.


CREATING A NEW TRANSLATION

When creating a new translation you must add your language code to the
Make_mvc.mak file in the lines defining LANGUAGES and MOFILES.  To create the
initial .po file for your language you must use the command:

	make -f make_mvc.mak first_time

Note: You need to be in the po directory when using this makefile.

Once you have your new .po file load it into Vim and source cleanup.vim, this
will convert untranslated messages to comments.  If you have syntax
highlighting turned on then untranslated messages will stand out more easily.

You will also need to edit the file names in the comments in the .po file.
You need to remove the absolute directory specification (which has the form
c:\vim61\src\).  You can do this in Vim with the following command with the
appropriate directory specification for where you have installed the Vim
source:

	%s/c:\\vim61\\src\\//g


UPDATING A TRANSLATION

If there are new or changed messages in Vim that need translating, then the
first thing to do is merge them into the existing translations.  This is done
with the following command:

	nmake -f Make_mvc.mak xx.po

where xx is the language code for the language needing translations.  The
original .po file is copied to xx.po.orig.


DOING THE TRANSLATION

Now that you have a .po file you can do the translations for all messages that
need it.  See README.txt for specific instructions.

Once you have finished translating the messages you should make sure all
non-translated strings are commented out.  This can be done by sourcing
cleanup.vim once again.


CHECKING THE TRANSLATION

Check the translation with the following command:

	nmake -f make_mvc.mak xx.mo

Correct any syntax errors reported.  When there are no more errors, the
translation is ready to be installed.


INSTALLING THE TRANSLATION

Install your translation with the following command:

	nmake -f make_mvc.mak install

This will create the xx\LC_MESSAGES directory in runtime\lang if it does not
already exist.
You can also use the following command to install all languages:

	nmake -f make_mvc.mak install-all


vim:tw=78:
