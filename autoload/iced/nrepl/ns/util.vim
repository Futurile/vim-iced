let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#ns#util#search() abort
  call cursor(1, 1)
  let line = trim(getline('.'))
  if line ==# '(ns' || line[0:3] ==# '(ns '
    return 1
  elseif line ==# '(in-ns' || line[0:7] ==# '(in-ns '
    return 1
  else
    let [l1, c1] = searchpos('(ns[ \r\n]', 'n')
    let [l2, c2] = searchpos('(in-ns[ \r\n]', 'n')
    if l1 == 0 && l2 == 0
      return 0
    elseif l1 != 0 && l2 == 0
      call cursor(l1, c1)
    elseif l1 == 0 && l2 != 0
      call cursor(l2, c2)
    elseif l1 < l2
      call cursor(l1, c1)
    else
      call cursor(l2, c2)
    endif
  endif

  return 1
endfunction

function! iced#nrepl#ns#util#replace(new_ns) abort
  let view = winsaveview()
  let reg_save = @@

  try
    if iced#nrepl#ns#util#search() == 0
      call iced#message#error('ns_not_found')
      return
    endif
    silent normal! dab

    let new_ns = trim(a:new_ns)
    let before_lnum = len(split(@@, '\r\?\n'))
    let after_lnum = len(split(new_ns, '\r\?\n'))
    let view['lnum'] = view['lnum'] + (after_lnum - before_lnum)

    if before_lnum == 1
      call iced#compat#deletebufline('%', line('.'), 1)
    endif

    let lnum = line('.') - 1
    call append(lnum, split(new_ns, '\r\?\n'))
  finally
    let @@ = reg_save
    if iced#nrepl#ns#util#search() != 0
      call iced#promise#wait(iced#format#current())
      call iced#nrepl#ns#load_current_file({_ -> ''})
    endif
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#ns#util#add_require_form(ns_code) abort
  let i = stridx(a:ns_code, '(:require')
  if i != -1
    return a:ns_code
  endif

  let i = strridx(a:ns_code, ')')
  let head = a:ns_code[0:i-1]
  let tail = strpart(a:ns_code, i)
  return printf("%s\n(:require)%s", head, tail)
endfunction

function! iced#nrepl#ns#util#add_namespace_to_require(ns_code, ns_name, ns_alias) abort
  let reqstart = stridx(a:ns_code, '(:require')
  let reqend = stridx(a:ns_code, ')', reqstart)

  let head = trim(a:ns_code[0:reqend-1])

  for postfix in [']', ')', "\r", "\n", "\t", ' ']
    if stridx(head, printf('%s%s', a:ns_name, postfix), reqstart) != -1
      return a:ns_code
    endif
  endfor

  let tail = trim(strpart(a:ns_code, reqend))
  let body = (empty(a:ns_alias) ? a:ns_name : printf('[%s :as %s]', a:ns_name, a:ns_alias))
  let head_len = len(head)
  if head[head_len-8:head_len-1] ==# ':require'
    return printf('%s %s%s', head, body, tail)
  else
    return printf("%s\n%s%s", head, body, tail)
  endif
endfunction

function! iced#nrepl#ns#util#add(ns_name, symbol_alias) abort
  let ns_alias = a:symbol_alias
  if a:ns_name ==# a:symbol_alias
    let ns_alias = ''
  endif

  let code = iced#nrepl#ns#get()
  let code = iced#nrepl#ns#util#add_require_form(code)
  let code = iced#nrepl#ns#util#add_namespace_to_require(code, a:ns_name, ns_alias)
  call iced#nrepl#ns#util#replace(code)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
