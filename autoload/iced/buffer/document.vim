let s:save_cpo = &cpoptions
set cpoptions&vim

let s:bufname = 'iced_document'
let s:default_filetype = 'markdown'

let g:iced#buffer#document#mods = get(g:, 'iced#buffer#document#mods', 'belowright')
let g:iced#buffer#document#height = get(g:, 'iced#buffer#document#height', &previewheight)

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&bufhidden', 'hide')
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', s:default_filetype)
  call setbufvar(a:bufnr, '&swapfile', 0)
endfunction

function! iced#buffer#document#init() abort
  return iced#buffer#init(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#document#is_visible() abort
  return iced#buffer#is_visible(s:bufname)
endfunction

function! iced#buffer#document#open(text, ...) abort
  let ft = get(a:, 1, s:default_filetype)
  call iced#buffer#set_var(s:bufname, '&filetype', ft)
  call iced#buffer#set_contents(s:bufname, a:text)

  let option = {
        \ 'opener': 'split',
        \  'mods': g:iced#buffer#document#mods,
        \  'scroll_to_top': v:true,
        \ }
  if g:iced#buffer#document#mods !=# 'vert'
        \ && g:iced#buffer#document#mods !=# 'vertical'
    let option['height'] = g:iced#buffer#document#height
  endif

  call iced#buffer#open(s:bufname, option)
endfunction

function! iced#buffer#document#update(text, ...) abort
  let ft = get(a:, 1, s:default_filetype)
  call iced#buffer#set_var(s:bufname, '&filetype', ft)
  call iced#buffer#set_contents(s:bufname, a:text)
endfunction

function! iced#buffer#document#close() abort
  call iced#buffer#close(s:bufname)
endfunction

function! iced#buffer#document#focus() abort
  call iced#buffer#focus(s:bufname)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
