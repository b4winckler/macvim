" vim:set ts=8 sts=2 sw=2 tw=0 et:

function! JobTimer(sec)
  let goal = localtime() + a:sec
  let job = { 'goal': goal, 'label': a:sec }

  function job.check() dict
    let remain = self.goal - localtime()
    return remain > 0 ? remain * 1000 : 0
  endfunction

  function job.onend() dict
    echo 'JobTimer#onend: ' . self.label
  endfunction

  call jobrun(job)
endfunction
