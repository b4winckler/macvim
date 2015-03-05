README_mac.txt for version 7.4 of Vim: Vi IMproved.

This file explains the installation of MacVim.
See "README.txt" for general information about Vim.
See "src/MacVim/README" for an overview of the MacVim specific source code.

MacVim uses the usual configure/make steps to build the binary but instead of
"make install" you just drag the app bundle into the directory you wish to
install in (usually `/Applications').


How to build and install
========================

Run `./configure` in the `src/` directory with the flags you want (call
`./configure --help` to see a list of flags) e.g.:

    $ cd src
    $ ./configure --with-features=huge \
                  --enable-rubyinterp \
                  --enable-pythoninterp \
                  --enable-perlinterp \
                  --enable-cscope

If you'd like to build with lua, use:

    $ ./configure --with-features=huge \
                  --enable-rubyinterp \
                  --enable-pythoninterp \
                  --enable-perlinterp \
                  --with-lua-prefix=/usr/local/Cellar/lua/5.1.5 \
                  --with-luajit \
                  --enable-luainterp \
                  --enable-cscope

These settings are for homebrew installed versions of luajit and lua 5.1.5.

Now build the project using `make`:

    $ make

The resulting app bundle will reside under `MacVim/build/Release`.  To try it
out quickly, type:

    $ open MacVim/build/Release/MacVim.app

To install MacVim, type

    $ open MacVim/build/Release

and drag the MacVim icon into your `Applications` folder.
