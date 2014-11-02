#!/bin/bash

###############################################################################
#
# Script for creating nice DMG installation image for MacVim.
# 
# Uses https://github.com/andreyvit/yoursway-create-dmg.
#
# Thanks to Drew Yeaton for awesome MacVim logo (used in background.png)
# http://dribbble.com/shots/337065-MacVim-Icon-Updated
#

# Directory with source files (MacVim.app, Readme.txt, mvim)
SOURCE="../build/Release/"

# MacVim version
VERSION="7.3"

# Volume title (i.e. application name)
TITLE="MacVim ${VERSION}"

# Background image
BGIMAGE='background.png'

# Volume icon
ICON="${SOURCE}/MacVim.app/Contents/Resources/MacVim.icns"

# Output .dmg file
DMGFILE="${TITLE}.dmg"

# Path to Andreyvit's create-dmg script 
CREATEDMG="yoursway-create-dmg/create-dmg"

$CREATEDMG --volname "${TITLE}" --volicon "${ICON}" --background "${BGIMAGE}" --window-size 650 480 \
	--icon-size 64 --icon MacVim.app 240 360 --icon Readme.txt 80 80 --icon mvim 570 80 --app-drop-link 410 360 \
	"${DMGFILE}" "${SOURCE}"
