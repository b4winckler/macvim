" vim:set ts=8 sts=2 sw=2 tw=0 et:

let job = { 'data': 'foo' }

function job.onend() dict
  echo '#onend ' . self.data
endfunction

call jobrun(job)
"call job.onend()
