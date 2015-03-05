# MacVim

This is slightly customized version of MacVim.

## Builds

For now, I plan to not provide snapshot releases until I can confirm they work
properly. In the meantime you must build the project yourself:

```
cd src
./configure --with-features=huge \
            --enable-rubyinterp \
            --enable-pythoninterp \
            --enable-perlinterp \
            --enable-cscope
make
open MacVim/build/Release
```

Built file will be in `MacVim/build/Release`.

If you'd like to build with lua support (this assumes you have lua 5.1.5 and luajit
installed via homebrew) use this configure call instead:

```
./configure --with-features=huge \
            --enable-rubyinterp \
            --enable-pythoninterp \
            --enable-perlinterp \
            --with-lua-prefix=/usr/local/Cellar/lua/5.1.5 \
            --with-luajit \
            --enable-luainterp \
            --enable-cscope
```

## Features

* Emoji support
* Improved icon (I will be adding improved filetype icons soon)
* Improved Yosemite integration

## Credits

* Logo by [Ethan Muller](https://dribbble.com/shots/1100850-Vim-Icon-Replacement)
* Yosemite tweaks and fixes https://github.com/b4winckler/macvim/pull/45
* Yosemite fullscreen fix https://github.com/jonashaag/macvim/commit/0c68453e1a6bb7150ab694b126f3db9cb8cd971f
