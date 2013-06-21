" vim:set ts=8 sts=2 sw=2 tw=0 et:

function! OnEnd() dict
  echo '#OnEnd ' . self.data
endfunction

let job = {
      \ 'data': 'foo',
      \ 'onend': function('OnEnd'),
      \ }

call jobrun(job)
"call job.onend()
