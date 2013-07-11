                   Vim version 7.3 香り屋版 導入マニュアル

                                                         Version: 1.7.3
                                                          Author: MURAOKA Taro
                                                           Since: 23-Aug-1999
                                                     Last Change: 17-Jun-2013.

概要
  Vimはviクローンに分類されるテキストエディタです。

  オリジナルのVimはhttp://www.vim.org/で公開されており、そのままでも日本語を含
  むテキストは編集できますが、香り屋では日本語をより扱い易くするための修正と追
  加を行い香り屋版として公開しています。

  リリースには32bit版と64bit版があります。32bit OSでは必ず32bit版をご利用くだ
  さい。64bit OSでは64bit版と32bit版どちらでもご利用いただけます。

インストール方法
  配布ファイルはZIP書庫です。配布ファイルにはVimプログラムフォルダが格納されて
  いるので、解凍してシステム内の好きな場所に配置してください。

  32bit版
    配布ファイル: vim73-kaoriya-win32-YYYYMMDD.zip
    Vimプログラムフォルダ: vim73-kaoriya-win32.zip

  64bit版
    配布ファイル: vim73-kaoriya-win64-YYYYMMDD.zip
    Vimプログラムフォルダ: vim73-kaoriya-win64

  上記のYYYYMMDDにはリリースの年月日が入ります。

実行方法
  Vimプログラムフォルダの中のgvimもしくはvimをダブルクリックしてください。

アンインストール (Windows)
  Vimプログラムフォルダを削除してください。特別な操作は不要です。

初心者の方へ
  まずはVimの操作に慣れるためトレーニングすることをオススメします。1回のトレー
  ニングにかかる時間には個人差がありますが30分から1時間くらいです。トレーニン
  グを開始するにはVimを起動した後

    :Tutorial

  と入力してリターンキーを押します。あとは画面に表示された文章にしたがって操作
  することで、Vimの基本的な操作を練習することができます。慣れるまで何度か繰り
  返し練習するとより効果的です。

Vimの拡張機能について
  本章ではVimの拡張機能の紹介とインストール方法について述べます。拡張機能をイ
  ンストールしなくても、Vimを使うことはできます。

  ctagsについて
    現在のVimはctagsを同梱していません。必要とする方は以下のサイトから各自入手
    しインストールしてください。

    - h_east's website (ctags日本語対応版バイナリ配布場所)
        http://hp.vector.co.jp/authors/VA025040/

    - ctagsオリジナルサイト
        http://ctags.sourceforge.net/

  Luaとの連携
    KaoriYa版にはLua (LuaJIT)がバンドルされているので、Luaインターフェースは自
    動的に有効になります。Luaインターフェースの詳細については":help lua"として
    Vim付属のマニュアルを参照してください。

    - LuaJIT サイト
        http://luajit.org/

  Perl(ActivePerl)との連携
    注意: PerlをインストールしなくてもVimは使用できます。

    ActiveState社により公開されているActivePerl 5.16をインストールすることで、
    Perlインターフェースを使用することができます。ActivePerlをインストールして
    いない場合は、Perlインターフェースは自動的に無効となります。Perlインター
    フェースの詳細については":help perl"としてVim付属のマニュアルを参照してく
    ださい。

    64bit版のVimを使う場合は64bit版のPerlを、32bit版を使う場合は32bit版のPerl
    をインストールしてください。

    - ActiveState社 (ActivePerl)
        http://www.activestate.com/

  Pythonとの連携
    注意: PythonをインストールしなくてもVimは使用できます。

    Python.orgにより公開されているPython 2.7をインストールすることで、Pythonイ
    ンターフェースを使用することができます。Pythonをインストールしていない場合
    は、Pythonインターフェースは自動的に無効となります。Pythonインターフェース
    の詳細については":help python"としてVim付属のマニュアルを参照してくださ
    い。

    64bit版のVimを使う場合は64bit版のPythonを、32bit版を使う場合は32bit版の
    Pythonをインストールしてください。

    - Python.org
        http://www.python.org/

  Python3との連携
    注意: Python3をインストールしなくてもVimは使用できます。

    Python.orgにより公開されているPython 3.3をインストールすることで、Pythonイ
    ンターフェースを使用することができます。Pythonをインストールしていない場合
    は、Pythonインターフェースは自動的に無効となります。Pythonインターフェース
    の詳細については":help python3"としてVim付属のマニュアルを参照してくださ
    い。

    64bit版のVimを使う場合は64bit版のPython3を、32bit版を使う場合は32bit版の
    Python3をインストールしてください。

    - Python.org
        http://www.python.org/

  Rubyとの連携
    注意: RubyをインストールしなくてもVimは使用できます。

    Ruby 2.0.0-p0をインストールするとRubyインターフェースを利用できます。Ruby
    をインストールしていない場合はRubyインターフェースは自動的に無効となりま
    す。Rubyインターフェースの詳細については":help ruby"としてVim付属のマニュ
    アルを参照してください。

    64bit版のVimを使う場合は64bit版のRubyを、32bit版を使う場合は32bit版の
    Rubyをインストールしてください。

    - Ruby 配布サイト
        http://rubyinstaller.org/
    - Ruby全般の情報
        http://www.ruby-lang.org/ja/

使用許諾
  香り屋版のライセンスはオリジナルのVimに従います。詳しくはorigdoc/README.txt
  をご覧下さい。

  Vimはチャリティーウェアと称していますが、オープンソースであり無料で使用する
  ことができます。しかしVimの利用に際して対価を支払いたいと考えたのならば、是
  非ウガンダの孤児達を援助するための寄付をお願いいたします。

  簡単な(無料の)寄付の方法
    海外からCDや本を注文する際に以下のリンクを経由して購入することで、その売上
    の何パーセントかが寄付されます。購入者には正規の代金以外の負担はありませ
    ん。洋書などが入用の際には、進んでご利用ください。

    - 買い物による寄付
      http://iccf-holland.org/click.html

  Vim開発スポンサー制度
    Vim開発スポンサー制度と機能要望投票制度が始まりました。有志がVimの開発にお
    金を出資しBram氏に開発へ専念してもらおうという主旨です。出資者には見返りに
    機能要望投票の権利が与えられます。最近ではfoldingがそうであったように、こ
    の機能要望投票で多くの票数を集めた機能から優先して実装されます。出資は1口
    10ユーロ以上からで、PayPalを通じてクレジットカードによる決済も可能です。ま
    た寄付した事実が公表されることを拒まなければ、100ユーロ以上寄付をした場合
    には「Hall of honour」に掲載されます。詳細は以下のURLを参照してください。

    - Sponsor Vim development
      http://www.vim.org/sponsor/index.php

オリジナルとの相違点
  ソース差分
    patchフォルダ内に差分を同梱しています。差分の使い方や内容に関する質問やコ
    メントなどありましたら香り屋版メンテナまで連絡ください。ソース1行1行に至る
    までの検証も大歓迎します。

    以下のレポジトリでは同パッチの最新版を公開しています。

    - vim-kaoriya-patches: +kaoriyaパッチのMercurial Queue
      https://bitbucket.org/koron/vim-kaoriya-patches

    patchフォルダ及びvim-kaoriya-patches内の名前がXで始まるパッチは非常に実験
    的なものであり公開版には適用されていません。興味のある方だけ御覧ください。

  Mercurial レポジトリ
    bitbucket.orgにて2つのレポジトリを公開しています。

    - vim-kaoriya: ビルド用スクリプト他
      https://bitbucket.org/koron/vim-kaoriya
    - vim-kaoriya-patches: +kaoriyaパッチのMercurial Queue
      https://bitbucket.org/koron/vim-kaoriya-patches

  Mercurialによるソースとパッチの入手方法
    香り屋版のソースコード(及びパッチ)をMercurialレポジトリから取得するには以
    下のようにしてください。

      $ hg qclone https://code.google.com/p/vim/ \
        -p https://bitbucket.org/koron/vim-kaoriya-patches
      $ cd vim
      $ hg qselect -n
      $ hg qpush -a

既知の問題点
  * qkcの-njフラグでコンバートしたJISファイルは開けない(iconv.dll)
  * scrolloffが窓高の丁度半分の時、下へのスクロールが2行単位になる

質問・連絡先
  日本のVimユーザ向けのGoogleグループ(vim_jp)が用意されています。どんなに簡単
  なことでもわからないことがあるのならばここで聞いてみると良いでしょう。きっと
  何らかの助けにはなるはずです。

    http://groups.google.com/group/vim_jp/?hl=ja

  もちろんメールで香り屋版メンテナに直接聞いてもらっても構いません。日本語化部
  分などの不都合は香り屋版メンテナまで連絡をいただければ、折をみて修正いたしま
  す。
  
  Vim本体に属すると思われる不都合については、直接Vim本家のほうへ英語で連絡する
  か、香り屋版メンテナに問い合わせてください。応急的に処置できるものであればそ
  うしますし、そうでなくても後日つたない英語になりますがVim本家へフィードバッ
  クできるかもしれません。Vim日本語版等の関連情報は次のURLにあります。

  - Vim本家
      http://www.vim.org/
  - Vimの日本コミュニティvim-jp
      http://vim-jp.org/
      https://github.com/vim-jp/issues/issues (バグ報告、機能要望)
  - vim_jp Google グループ
      http://groups.google.com/group/vim_jp/?hl=ja
  - Vimドキュメント翻訳(vimdoc-ja)
      https://github.com/vim-jp/vimdoc-ja/
  - 香り屋版メンテナ
      http://www.kaoriya.net/software/vim
      MURAOKA Taro <koron.kaoriya@gmail.com>
      Twitter @kaoriya

謝辞
  何よりも、素晴らしいエディタであるVimをフリーソフトウェアとして公開&管理し、
  今回の日本語版の公開を快諾していただいたBram Moolenaar氏に最大の感謝をいたし
  ます。また、この配布パッケージには以下の方々によるファイル・ドキュメントが含
  まれています。加えて香り屋版の作成に関連して、多くの方々から様々なアイデアや
  バグ報告をいただきました。皆様協力ありがとうございます。

  (アルファベット順)
  - 215 (Vim掲示板:1587)
    autodate.vimの英語ドキュメント添削
  - FUJITA Yasuhiro <yasuhiroff@ka.baynet.ne.jp>
    runtime/keymap/tcode_cp932.vim (マップ修正・追加)
  - KIHARA, Hideto <deton@m1.interq.or.jp>
    runtime/keymap/tutcode_cp932.vim
  - MATSUMOTO Yasuhiro <mattn_jp@hotmail.com>
    diffs/ (一部コード流用/アドバイス/遊び仲間)
    googletranslate.vim
  - NAKADAIRA Yukihiro <http://code.google.com/u/yukihiro.nakadaira/>
    plugins/autofmt
  - NISHIOKA Takuhiro <takuhiro@super.win.ne.jp>
    runtime/plugin/format.vim (Vim6対応改造版)
  - TAKASUKA Yoshihiro <tesuri@d1.dion.ne.jp>
    runtime/keymap/tcode_cp932.vim

  そして総てのVimユーザに。

------------------------------------------------------------------------------
                  生きる事への強い意志が同時に自分と異なる生命をも尊ぶ心となる
                                        MURAOKA Taro <koron.kaoriya@gmail.com>
 vim:set ts=8 sts=2 sw=2 tw=78 et ft=memo:
