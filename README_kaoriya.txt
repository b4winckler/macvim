                   Vim version 7.2 香り屋版 導入マニュアル

                                                         Version: 1.5.1
                                                          Author: MURAOKA Taro
                                                           Since: 23-Aug-1999
                                                     Last Change: 12-Mar-2010.

概要
  Vimはviクローンに分類されるテキストエディタです。

  オリジナルのVimはhttp://www.vim.org/で公開されており、そのままでも日本語を含
  むテキストは編集できますが、香り屋では日本語をより扱い易くするための修正と追
  加を行い香り屋版として公開しています。

  リリースには32bit版と64bit版があります。32bit OSでは必ず32bit版をご利用くだ
  さい。64bit OSでは64bit版も32bit版もどちらもご利用いただけます。


インストール方法
  配布ファイルはZIP書庫です。配布ファイルにはVimプログラムフォルダが格納されて
  いるので、解凍してシステム内の好きな場所に配置してください。

  32bit版
    配布ファイル: vim72-YYYYMMDD-kaoriya-w32j.zip
    Vimプログラムフォルダ: vim72-kaoriya-w32j

  64bit版
    配布ファイル: vim72-YYYYMMDD-kaoriya-w64j.zip
    Vimプログラムフォルダ: vim72-kaoriya-w64j

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

  Perl(ActivePerl)との連携
    注意: PerlをインストールしなくてもVimは使用できます。

    ActiveState社により公開されているActivePerl 5.10をインストールすることで、
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

    Python.orgにより公開されているPython 2.6をインストールすることで、Pythonイ
    ンターフェースを使用することができます。Pythonをインストールしていない場合
    は、Pythonインターフェースは自動的に無効となります。Pythonインターフェース
    の詳細については":help python"としてVim付属のマニュアルを参照してくださ
    い。

    64bit版のVimを使う場合は64bit版のPythonを、32bit版を使う場合は32bit版の
    Pythonをインストールしてください。

    - Python.org
        http://www.python.org/

  Rubyとの連携
    注意: Rubyとの連携機能は提供いたしません。

    一般的に配布されているRuby(64bit版)との間でコンパイラのバージョンが異なる
    ため、Vim側で対応することが容易ではありません。

    - Ruby-mswin32 配布サイト
        http://www.ruby-lang.org/ja/
        http://www.garbagecollect.jp/ruby/mswin32/ja/

使用許諾
  香り屋版のライセンスはオリジナルのVimに従います。詳しくはREADME.txtをご覧下
  さい。

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
    patchesフォルダ内にhg diffによって取得した差分を同梱しています。差分の使い
    方や内容に関する質問やコメントなどありましたら香り屋版メンテナまで連絡くだ
    さい。ソース1行1行に至るまでの検証も大歓迎します。

既知の問題点
  * qkcの-njフラグでコンバートしたJISファイルは開けない(iconv.dll)
  * scrolloffが窓高の丁度半分の時、スクロールが2行単位になる
  * 書き込み時にNTFSのハードリンクが切れる

質問・連絡先
  日本のVimユーザ向けのGoogleグループ(vim_jp)が用意されています。どんなに簡単
  なことでもわからないことがあるのならばここで聞いてみると良いでしょう。きっと
  何らかの助けにはなるはずです。

    http://groups.google.com/group/vim_jp?hl=ja

  もちろんメールで香り屋版メンテナに直接聞いてもらっても構いません。日本語化部
  分などの不都合は香り屋版メンテナまで連絡をいただければ、折をみて修正いたしま
  す。
  
  Vim本体に属すると思われる不都合については、直接Vim本家のほうへ英語で連絡する
  か、香り屋版メンテナに問い合わせてください。応急的に処置できるものであればそ
  うしますし、そうでなくても後日つたない英語になりますがVim本家へフィードバッ
  クできるかもしれません。Vim日本語版等の関連情報は次のURLにあります。

  - Vim本家
      http://www.vim.org/
  - Vim日本語版情報
      http://www.kaoriya.net/#VIM
  - vim_jp Google グループ
      http://groups.google.com/group/vim_jp?hl=ja
  - 香り屋版メンテナ
      MURAOKA Taro <koron.kaoriya@gmail.com>

謝辞
  何よりも、素晴らしいエディタであるVimをフリーソフトウェアとして公開&管理し、
  今回の日本語版の公開を快諾していただいたBram Moolenaar氏に最大の感謝をいたし
  ます。また、この配布パッケージには以下の方々によるファイル・ドキュメントが含
  まれています。加えて香り屋版の作成に関連して、多くの方いから様々なアイデアや
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
  - NISHIOKA Takuhiro <takuhiro@super.win.ne.jp>
    runtime/plugin/format.vim (Vim6対応改造版)
  - TAKASUKA Yoshihiro <tesuri@d1.dion.ne.jp>
    runtime/keymap/tcode_cp932.vim

  そして総てのVimユーザに。

------------------------------------------------------------------------------
                  生きる事への強い意志が同時に自分と異なる生命をも尊ぶ心となる
                                        MURAOKA Taro <koron.kaoriya@gmail.com>
 vim:set ts=8 sts=2 sw=2 tw=78 et ft=memo:
