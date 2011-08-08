" vi:set ts=8 sts=8 sw=8 tw=0:
"
" Menu Translations:	Japanese (UTF-8)
" Translated By:	MURAOKA Taro  <koron@tka.att.ne.jp>
" Last Change:		10-Jun-2010.

" Quit when menu translations have already been done.
if exists("did_menu_trans")
  finish
endif
let did_menu_trans = 1

scriptencoding utf-8

" Help menu
menutrans &Help			ヘルプ
menutrans &Overview<Tab><F1>	概略<Tab><F1>
menutrans &User\ Manual		ユーザマニュアル
menutrans &How-to\ links	&How-toリンク
menutrans &Credits		クレジット
menutrans Co&pying		著作権情報
menutrans &Sponsor/Register	スポンサー/登録
menutrans O&rphans		孤児
menutrans &Version		バージョン情報
menutrans &About		Vimについて

let g:menutrans_help_dialog = "ヘルプを検索したいコマンドもしくは単語を入力してください:\n\n挿入モードのコマンドには i_ を先頭に付加します. (例: i_CTRL-X)\nコマンドライン編集コマンドには c_ を先頭に付加します. (例: c_<Del>)\nオプションの名前には ' を付加します. (例: 'shiftwidth')"

" File menu
menutrans &File				ファイル
menutrans &Open\.\.\.<Tab>:e		開く\.\.\.<Tab>:e
menutrans Sp&lit-Open\.\.\.<Tab>:sp	分割して開く\.\.\.<Tab>:sp
menutrans Open\ Tab\.\.\.<Tab>:tabnew	タブで開く<Tab>:tabnew
menutrans &New<Tab>:enew		新規作成<Tab>:enew
menutrans &Close<Tab>:close		閉じる<Tab>:close
menutrans &Save<Tab>:w			保存<Tab>:w
menutrans Save\ &As\.\.\.<Tab>:sav	名前を付けて保存\.\.\.<Tab>:sav
menutrans Split\ &Diff\ with\.\.\.	差分表示\.\.\.
menutrans Split\ Patched\ &By\.\.\.	パッチ結果を表示\.\.\.
menutrans &Print			印刷
menutrans Sa&ve-Exit<Tab>:wqa		保存して終了<Tab>:wqa
menutrans E&xit<Tab>:qa			終了<Tab>:qa

" Edit menu
menutrans &Edit				編集
menutrans &Undo<Tab>u			取り消す<Tab>u
menutrans &Redo<Tab>^R			やり直す<Tab>^R
menutrans Rep&eat<Tab>\.		繰り返す<Tab>\.
menutrans Cu&t<Tab>"+x			カット<Tab>"+x
menutrans &Copy<Tab>"+y			コピー<Tab>"+y
menutrans &Paste<Tab>"+gP		ペースト<Tab>"+gP
menutrans Put\ &Before<Tab>[p		前にペースト<Tab>[p
menutrans Put\ &After<Tab>]p		後にペースト<Tab>]p
menutrans &Delete<Tab>x			消す<Tab>x
menutrans &Select\ All<Tab>ggVG		全て選択<Tab>ggVG
menutrans &Find\.\.\.			検索\.\.\.
menutrans &Find<Tab>/			検索<Tab>/
menutrans Find\ and\ Rep&lace\.\.\.	置換\.\.\.
menutrans Find\ and\ Rep&lace<Tab>:%s	置換<Tab>:%s
menutrans Find\ and\ Rep&lace<Tab>:s	置換<Tab>:s
"menutrans Options\.\.\.			オプション\.\.\.
menutrans Settings\ &Window		設定ウインドウ
menutrans Startup\ &Settings		起動時の設定

" Edit/Global Settings
menutrans &Global\ Settings		全体設定
menutrans Toggle\ Pattern\ &Highlight<Tab>:set\ hls!
	\	パターン強調切替<Tab>:set\ hls!
menutrans Toggle\ &Ignore-case<Tab>:set\ ic!
	\	大小文字区別切替<Tab>:set\ ic!
menutrans Toggle\ &Showmatch<Tab>:set\ sm!
	\	マッチ表示切替<Tab>:set\ sm!
menutrans &Context\ lines		カーソル周辺行数
menutrans &Virtual\ Edit		仮想編集
menutrans Never				無効
menutrans Block\ Selection		ブロック選択時
menutrans Insert\ mode			挿入モード時
menutrans Block\ and\ Insert		ブロック/挿入モード時
menutrans Always			常時
menutrans Toggle\ Insert\ &Mode<Tab>:set\ im!
	\	挿入(初心者)モード切替<Tab>:set\ im!
menutrans Toggle\ Vi\ C&ompatible<Tab>:set\ cp!
	\	Vi互換モード切替<Tab>:set\ cp!
menutrans Search\ &Path\.\.\.		検索パス\.\.\.
menutrans Ta&g\ Files\.\.\.		タグファイル\.\.\.
"
" GUI options
menutrans Toggle\ &Toolbar		ツールバー表示切替
menutrans Toggle\ &Bottom\ Scrollbar	スクロールバー(下)表示切替
menutrans Toggle\ &Left\ Scrollbar	スクロールバー(左)表示切替
menutrans Toggle\ &Right\ Scrollbar	スクロールバー(右)表示切替

let g:menutrans_path_dialog = "ファイルの検索パスを入力してください:\nディレクトリ名はカンマ ( , ) で区切ってください."
let g:menutrans_tags_dialog = "タグファイルの名前を入力してください:\n名前はカンマ ( , ) で区切ってください."

" Edit/File Settings

" Boolean options
menutrans F&ile\ Settings		ファイル設定
menutrans Toggle\ Line\ &Numbering<Tab>:set\ nu!
	\	行番号表示切替<Tab>:set\ nu!
menutrans Toggle\ &List\ Mode<Tab>:set\ list!
	\ リストモード切替<Tab>:set\ list!
menutrans Toggle\ Line\ &Wrap<Tab>:set\ wrap!
	\	行折返し切替<Tab>:set\ wrap!
menutrans Toggle\ W&rap\ at\ word<Tab>:set\ lbr!
	\	単語折返し切替<Tab>:set\ lbr!
menutrans Toggle\ &expand-tab<Tab>:set\ et!
	\	タブ展開切替<Tab>:set\ et!
menutrans Toggle\ &auto-indent<Tab>:set\ ai!
	\	自動字下げ切替<Tab>:set\ ai!
menutrans Toggle\ &C-indenting<Tab>:set\ cin!
	\	C言語字下げ切替<Tab>:set\ cin!

" other options
menutrans &Shiftwidth			シフト幅
menutrans Soft\ &Tabstop		ソフトウェアタブ幅
menutrans Te&xt\ Width\.\.\.		テキスト幅\.\.\.
menutrans &File\ Format\.\.\.		改行記号選択\.\.\.

let g:menutrans_textwidth_dialog = "テキストの幅('textwidth')を設定してください (0で整形を無効化):"
let g:menutrans_fileformat_dialog = "ファイル出力の際の改行記号の形式を選んでください."
let g:menutrans_fileformat_choices = "&Unix\n&Dos\n&Mac\nキャンセル"

menutrans C&olor\ Scheme		色テーマ選択
menutrans &Keymap			キーマップ
menutrans None				なし

" Programming menu
menutrans &Tools			ツール
menutrans &Jump\ to\ this\ tag<Tab>g^]	タグジャンプ<Tab>g^]
menutrans Jump\ &back<Tab>^T		戻る<Tab>^T
menutrans Build\ &Tags\ File		タグファイル作成
menutrans &Make<Tab>:make		メイク<Tab>:make
menutrans &List\ Errors<Tab>:cl		エラーリスト<Tab>:cl
menutrans L&ist\ Messages<Tab>:cl!	メッセージリスト<Tab>:cl!
menutrans &Next\ Error<Tab>:cn		次のエラーへ<Tab>:cn
menutrans &Previous\ Error<Tab>:cp	前のエラーへ<Tab>:cp
menutrans &Older\ List<Tab>:cold	古いリスト<Tab>:cold
menutrans N&ewer\ List<Tab>:cnew	新しいリスト<Tab>:cnew
menutrans Error\ &Window		エラーウインドウ
menutrans &Update<Tab>:cwin		更新<Tab>:cwin
menutrans &Open<Tab>:copen		開く<Tab>:copen
menutrans &Close<Tab>:cclose		閉じる<Tab>:cclose
menutrans &Convert\ to\ HEX<Tab>:%!xxd	HEXへ変換<Tab>:%!xxd
menutrans Conve&rt\ back<Tab>:%!xxd\ -r	HEXから逆変換<Tab>%!xxd\ -r
menutrans Se&T\ Compiler		コンパイラ設定

" Tools.Spelling Menu
menutrans &Spelling			スペリング
menutrans &Spell\ Check\ On		スペルチェック有効
menutrans Spell\ Check\ &Off		スペルチェック有効
menutrans To\ &Next\ error<Tab>]s	次のエラー<Tab>]s
menutrans To\ &Previous\ error<Tab>[s	前のエラー<Tab>[s
menutrans Suggest\ &Corrections<Tab>z=	修正候補<Tab>z=
menutrans &Repeat\ correction<Tab>:spellrepall	修正を繰り返す<Tab>:spellrepall
menutrans Set\ language\ to\ "en"	言語を\ "en"\ に設定する
menutrans Set\ language\ to\ "en_au"	言語を\ "en_au"\ に設定する
menutrans Set\ language\ to\ "en_ca"	言語を\ "en_ca"\ に設定する
menutrans Set\ language\ to\ "en_gb"	言語を\ "en_gb"\ に設定する
menutrans Set\ language\ to\ "en_nz"	言語を\ "en_nz"\ に設定する
menutrans Set\ language\ to\ "en_us"	言語を\ "en_us"\ に設定する
menutrans &Find\ More\ Languages	他の言語を検索する

" Tools.Fold Menu
menutrans &Folding			折畳み
" open close folds
menutrans &Enable/Disable\ folds<Tab>zi	有効/無効切替<Tab>zi
menutrans &View\ Cursor\ Line<Tab>zv	カーソル行を表示<Tab>zv
menutrans Vie&w\ Cursor\ Line\ only<Tab>zMzx	カーソル行だけを表示<Tab>zMzx
menutrans C&lose\ more\ folds<Tab>zm	折畳みを閉じる<Tab>zm
menutrans &Close\ all\ folds<Tab>zM	全折畳みを閉じる<Tab>zM
menutrans O&pen\ more\ folds<Tab>zr	折畳みを開く<Tab>zr
menutrans &Open\ all\ folds<Tab>zR	全折畳みを開く<Tab>zR
" fold method
menutrans Fold\ Met&hod			折畳み方法
menutrans M&anual			手動
menutrans I&ndent			インデント
menutrans E&xpression			式評価
menutrans S&yntax			シンタックス
menutrans &Diff				差分
menutrans Ma&rker			マーカー
" create and delete folds
menutrans Create\ &Fold<Tab>zf		折畳み作成<Tab>zf
menutrans &Delete\ Fold<Tab>zd		折畳み削除<Tab>zd
menutrans Delete\ &All\ Folds<Tab>zD	全折畳み削除<Tab>zD
" moving around in folds
menutrans Fold\ col&umn\ width		折畳みカラム幅

menutrans &Update		更新
menutrans &Get\ Block		ブロック抽出
menutrans &Put\ Block		ブロック適用

" Names for buffer menu.
menutrans &Buffers		バッファ
menutrans &Refresh\ menu	メニュー再読込
menutrans &Delete		削除
menutrans &Alternate		裏へ切替
menutrans &Next			次のバッファ
menutrans &Previous		前のバッファ
menutrans [No\ File]		[無題]
let g:menutrans_no_file = "[無題]"

" Window menu
menutrans &Window			ウインドウ
"menutrans &New<Tab>^Wn			新規作成<Tab>^Wn
"menutrans S&plit<Tab>^Ws		分割<Tab>^Ws
"menutrans Sp&lit\ To\ #<Tab>^W^^	裏バッファへ分割<Tab>^W^^
"menutrans Split\ &Vertically<Tab>^Wv	垂直分割<Tab>^Wv
"menutrans Split\ File\ E&xplorer	ファイルエクスプローラ
"menutrans &Close<Tab>^Wc		閉じる<Tab>^Wc
"menutrans Move\ &To			移動
"menutrans &Top<Tab>^WK			上<Tab>^WK
"menutrans &Bottom<Tab>^WJ		下<Tab>^WJ
"menutrans &Left\ side<Tab>^WH		左<Tab>^WH
"menutrans &Right\ side<Tab>^WL		右<Tab>^WL
"menutrans Close\ &Other(s)<Tab>^Wo	他を閉じる<Tab>^Wo
"menutrans Ne&xt<Tab>^Ww			次へ<Tab>^Ww
"menutrans P&revious<Tab>^WW		前へ<Tab>^WW
"menutrans &Equal\ Size<Tab>^W=	同じ高さに<Tab>^W=
"menutrans &Max\ Height<Tab>^W_		最大高に<Tab>^W_
"menutrans M&in\ Height<Tab>^W1_		最小高に<Tab>^W1_
"menutrans Max\ &Width<Tab>^W\|		最大幅に<Tab>^W\|
"menutrans Min\ Widt&h<Tab>^W1\|		最小幅に<Tab>^W1\|
"menutrans Rotate\ &Up<Tab>^WR		上にローテーション<Tab>^WR
"menutrans Rotate\ &Down<Tab>^Wr		下にローテーション<Tab>^Wr
"menutrans Select\ Fo&nt\.\.\.		フォント設定\.\.\.

" The popup menu
menutrans &Undo			取り消す
menutrans Cu&t			カット
menutrans &Copy			コピー
menutrans &Paste		ペースト
menutrans &Delete		削除
menutrans Select\ Blockwise	矩形ブロック選択
menutrans Select\ &Word		単語選択
menutrans Select\ &Line		行選択
menutrans Select\ &Block	ブロック選択
menutrans Select\ &All		すべて選択
menutrans Select\ &Sentence	文選択
menutrans Select\ Pa&ragraph	段落選択

" The GUI toolbar (for Win32 or GTK)
if has("toolbar")
  if exists("*Do_toolbar_tmenu")
    delfun Do_toolbar_tmenu
  endif
  fun Do_toolbar_tmenu()
    tmenu ToolBar.Open		ファイルを開く
    tmenu ToolBar.Save		現在のファイルを保存
    tmenu ToolBar.SaveAll	すべてのファイルを保存
    tmenu ToolBar.Print		印刷
    tmenu ToolBar.Undo		取り消し
    tmenu ToolBar.Redo		もう一度やる
    tmenu ToolBar.Cut		クリップボードへ切り取り
    tmenu ToolBar.Copy		クリップボードへコピー
    tmenu ToolBar.Paste		クリップボードから貼り付け
    tmenu ToolBar.Find		検索...
    tmenu ToolBar.FindNext	次を検索
    tmenu ToolBar.FindPrev	前を検索
    tmenu ToolBar.Replace	置換...
    if 0	" disabled; These are in the Windows menu
      tmenu ToolBar.New		新規ウインドウ作成
      tmenu ToolBar.WinSplit	ウインドウ分割
      tmenu ToolBar.WinMax	ウインドウ最大化
      tmenu ToolBar.WinMin	ウインドウ最小化
      tmenu ToolBar.WinClose	ウインドウを閉じる
    endif
    tmenu ToolBar.LoadSesn	セッション読込
    tmenu ToolBar.SaveSesn	セッション保存
    tmenu ToolBar.RunScript	Vimスクリプト実行
    tmenu ToolBar.Make		プロジェクトをMake
    tmenu ToolBar.Shell		シェルを開く
    tmenu ToolBar.RunCtags	tags作成
    tmenu ToolBar.TagJump	タグジャンプ
    tmenu ToolBar.Help		Vimヘルプ
    tmenu ToolBar.FindHelp	Vimヘルプ検索
  endfun
endif

" Syntax menu
menutrans &Syntax		シンタックス
menutrans &Show\ filetypes\ in\ menu	対応形式をメニューに表示
menutrans Set\ '&syntax'\ only	'syntax'だけ設定
menutrans Set\ '&filetype'\ too	'filetype'も設定
menutrans &Off			無効化
menutrans &Manual		手動設定
menutrans A&utomatic		自動設定
menutrans on/off\ for\ &This\ file
	\	オン/オフ切替
menutrans Co&lor\ test		カラーテスト
menutrans &Highlight\ test	ハイライトテスト
menutrans &Convert\ to\ HTML	HTMLへコンバート

" Japanese specific menu
" 成否はiconv次第、必ずしも指定したエンコードになるわけではないことに注意
if has('iconv')
  " iconvのバージョン判定
  let support_jisx0213 = (iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb") ? 1 : 0
  "
  " 読み込み
  an 10.395 &File.-SEPICONV- <Nop>
  an 10.396.100.100 &File.エンコード指定\.\.\..開く\.\.\..SJIS<Tab>fenc=cp932 :browse confirm e ++enc=cp932<CR>
  if !support_jisx0213
    an 10.396.100.110 &File.エンコード指定\.\.\..開く\.\.\..EUC<Tab>fenc=euc-jp :browse confirm e ++enc=euc-jp<CR>
    an 10.396.100.120 &File.エンコード指定\.\.\..開く\.\.\..JIS<Tab>fenc=iso-2022-jp :browse confirm e ++enc=iso-2022-jp<CR>
  else
    an 10.396.100.110 &File.エンコード指定\.\.\..開く\.\.\..EUC<Tab>fenc=euc-jisx0213 :browse confirm e ++enc=euc-jisx0213<CR>
    an 10.396.100.120 &File.エンコード指定\.\.\..開く\.\.\..JIS<Tab>fenc=iso-2022-jp-3 :browse confirm e ++enc=iso-2022-jp-3<CR>
  endif
  an 10.396.100.130 &File.エンコード指定\.\.\..開く\.\.\..UTF-8<Tab>fenc=utf-8 :browse confirm e ++enc=utf-8<CR>

  " 再読込
  an 10.396.110.100 &File.エンコード指定\.\.\..再読込\.\.\..SJIS<Tab>fenc=cp932 :e ++enc=cp932<CR>
  if !support_jisx0213
    an 10.396.110.110 &File.エンコード指定\.\.\..再読込\.\.\..EUC<Tab>fenc=euc-jp :e ++enc=euc-jp<CR>
    an 10.396.110.120 &File.エンコード指定\.\.\..再読込\.\.\..JIS<Tab>fenc=iso-2022-jp :e ++enc=iso-2022-jp<CR>
  else
    an 10.396.110.110 &File.エンコード指定\.\.\..再読込\.\.\..EUC<Tab>fenc=euc-jisx0213 :e ++enc=euc-jisx0213<CR>
    an 10.396.110.120 &File.エンコード指定\.\.\..再読込\.\.\..JIS<Tab>fenc=iso-2022-jp-3 :e ++enc=iso-2022-jp-3<CR>
  endif
  an 10.396.110.130 &File.エンコード指定\.\.\..再読込\.\.\..UTF-8<Tab>fenc=utf-8 :e ++enc=utf-8<CR>

  " 保存
  an 10.396.115 &File.エンコード指定\.\.\..-SEP1- <Nop>
  an 10.396.120.100 &File.エンコード指定\.\.\..保存\.\.\..SJIS<Tab>fenc=cp932 :set fenc=cp932 \| w<CR>
  if !support_jisx0213
    an 10.396.120.110 &File.エンコード指定\.\.\..保存\.\.\..EUC<Tab>fenc=euc-jp :set fenc=euc-jp \| w<CR>
    an 10.396.120.120 &File.エンコード指定\.\.\..保存\.\.\..JIS<Tab>fenc=iso-2022-jp :set fenc=iso-2022-jp \| w<CR>
  else
    an 10.396.120.110 &File.エンコード指定\.\.\..保存\.\.\..EUC<Tab>fenc=euc-jisx0213 :set fenc=euc-jisx0213 \| w<CR>
    an 10.396.120.120 &File.エンコード指定\.\.\..保存\.\.\..JIS<Tab>fenc=iso-2022-jp-3 :set fenc=iso-2022-jp-3 \| w<CR>
  endif
  an 10.396.120.130 &File.エンコード指定\.\.\..保存\.\.\..UTF-8<Tab>fenc=utf-8 :set fenc=utf-8 \| w<CR>
endif


"---------------------------------------------------------------------------
" Extra Japanese menus
"---------------------------------------------------------------------------

" File menu
menut New\ Window		新規ウインドウ
menut New\ Tab			新規タブ
menut Open\.\.\.		開く\.\.\.
menut Open\ Recent		最近開いたファイル
menut Close\ Window<Tab>:qa	ウインドウを閉じる<Tab>:qa
menut Close			閉じる
menut Save\ All			すべてを保存
menut Save\ As\.\.\.<Tab>:sav	名前を付けて保存\.\.\.<Tab>:sav

" Edit menu
menut Find			検索
menut Find\.\.\.		検索\.\.\.
menut Find\ Next		次を検索
menut Find\ Previous		前を検索
menut Use\ Selection\ for\ Find	選択部分を検索に使用

menut Font			フォント
menut Show\ Fonts		フォントパネルを表示
menut Bigger			大きく
menut Smaller			小さく
menut Special\ Characters\.\.\. 特殊文字\.\.\.

" Window menu
menut Minimize			しまう
menut Minimize\ All		すべてをしまう
menut Zoom			拡大／縮小
menut Zoom\ All			すべてを拡大
menut Toggle\ Full\ Screen\ Mode	フルスクリーンモード切り替え
menut Select\ Next\ Window		次のウインドウ
menut Select\ Previous\ Window	前のウインドウ
menut Select\ Next\ Tab		次のタブを選択
menut Select\ Previous\ Tab	前のタブを選択
menut Bring\ All\ To\ Front	すべてを手前に移動

" Help menu
menut MacVim\ Help		MacVim\ ヘルプ
menut MacVim\ Website		MacVim\ Webサイト
an <silent> 9999.4 &Help.MacVim-KaoriYa\ Webサイト	<Nop>
macm ヘルプ.MacVim-KaoriYa\ Webサイト		action=openWebsiteKaoriYa:
an 9999.5 &Help.-sep0-			<Nop>


" filler to avoid the line above being recognized as a modeline
" filler
" filler
" filler


