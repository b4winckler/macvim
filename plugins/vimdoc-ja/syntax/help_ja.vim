scriptencoding utf-8

syn match helpVim "Vim バージョン [0-9.a-z]\+"
syn match helpVim "VIMリファレンス.*"
syn region helpNotVi start="{Vim" end="}" contains=helpLeadBlank,helpHyperTextJump
