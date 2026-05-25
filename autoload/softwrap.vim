" Repaint, by swapping to a blank temp buffer at full size to paint blank,
" then resize, then back to the user's buffer.
func! softwrap#ResizeColumns(target_cols)
  " Shouldn't be called before softwrap#Setup
  if !exists('g:softwrap_term_cols') | return | endif
  " Clamp to true size
  let l:cols = min([a:target_cols, g:softwrap_term_cols])
  " Don't update if nothing would change
  if &columns == l:cols | return | endif

  " Stash buffers to restore later
  let l:cur_buf = bufnr('%')
  let l:alt_buf = bufnr('#')

  " Create a temp buffer to wipe the screen at the current size
  noautocmd enew!
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  redraw!
  " Tell vim we're in a smaller screen than we are
  noautocmd execute 'set columns=' . l:cols

  " Restore buffers
  if l:alt_buf > 0 && l:alt_buf != l:cur_buf && bufexists(l:alt_buf)
    noautocmd execute 'keepalt buffer ' . l:alt_buf
    noautocmd execute 'buffer ' . l:cur_buf
  else
    noautocmd execute 'keepalt buffer ' . l:cur_buf
  endif
endfunc

" This prevents an infinite loop caused by calling softwrap#ResizeColumns from
" `autocmd VimResized`; vim appears to re-trigger VimResized in that case but
" not if we call softwrap#ResizeColumns directly.
" Instead it uses an immediate timer to update the size.
func! softwrap#QueueResize(target_cols)
  " Update the stored real size
  let g:softwrap_term_cols = &columns
  " Stash for retrieval - latest value wins
  " Vimscript is single threaded, so this is safe.
  let g:softwrap_queued_cols = a:target_cols

  " Cancel any pending timer so it only happens once
  if exists('g:softwrap_resize_timer')
    call timer_stop(g:softwrap_resize_timer)
  endif
  " Call immediately (0)
  let g:softwrap_resize_timer = timer_start(0, {t -> softwrap#ApplyResize()})
endfunc

func! softwrap#ApplyResize()
  unlet! g:softwrap_resize_timer

  " Run the resize, once. Clean up.
  if exists('g:softwrap_queued_cols')
    let l:target = g:softwrap_queued_cols
    unlet g:softwrap_queued_cols
    call softwrap#ResizeColumns(l:target)
  endif
endfunc

" Entry point
func! softwrap#Setup(...)
  " We require timer support at least; 2016 vim
  if !exists('*timer_start')
    echoerr 'softwrap requires Vim 7.4.1649+ (timer support)'
    return
  endif

  " Default value of 80
  let l:width = a:0 > 0 ? a:1 : 80
  " Treat gutter size as just 4; too much bother to recalculate columns every
  " time the gutter changes, with file swaps, new lines, linter warnings, etc.
  let l:gutter = 4

  let l:target_cols = l:width + l:gutter

  " Stash window size on first load; we'll update it throughout after
  if !exists('g:softwrap_term_cols')
    let g:softwrap_term_cols = &columns
  endif

  " Stash user variables before we stomp on them
  if !exists('g:softwrap_saved')
    let g:softwrap_saved = {
      \ 'wrap':        &wrap,
      \ 'linebreak':   &linebreak,
      \ 'textwidth':   &textwidth,
      \ 'colorcolumn': &colorcolumn,
      \ 'cursorline':  &cursorline,
      \ 'cursorcolumn': &cursorcolumn,
      \ }
  endif
  " wrap is the goal, linebreak on words
  " disable textwidth and colorcolumn since this replaces their role
  set wrap linebreak textwidth=0 colorcolumn=
  " cursorline and cursorcolumn don't work well with wrap
  set nocursorline nocursorcolumn

  " Repaint
  call softwrap#ResizeColumns(l:target_cols)

  " On resize, queue a repaint
  augroup SoftwrapColumns
    autocmd!
    execute 'autocmd VimResized * call softwrap#QueueResize(' . l:target_cols . ')'
    " Don't keep running when we're trying to quit vim; clean up to ensure no
    " odd halfway state
    autocmd VimLeavePre * call softwrap#Disable()
  augroup END
endfunc

" Cleanup
func! softwrap#Disable()
  " Clean up augroups and timer
  augroup SoftwrapColumns
    autocmd!
  augroup END
  if exists('g:softwrap_resize_timer')
    call timer_stop(g:softwrap_resize_timer)
    unlet g:softwrap_resize_timer
  endif
  unlet! g:softwrap_queued_cols

  " Don't assume the variable exists; could be called before setup
  if exists('g:softwrap_term_cols')
    " We don't need the fancy repaint since this is the full width
    noautocmd execute 'set columns=' . g:softwrap_term_cols
    unlet! g:softwrap_term_cols
    redraw!
  endif

  if !exists('g:softwrap_saved') | return | endif

  " Restore user's settings
  let s = g:softwrap_saved

  let &wrap        = s.wrap
  let &textwidth   = s.textwidth
  let &linebreak   = s.linebreak
  let &colorcolumn = s.colorcolumn
  let &cursorline  = s.cursorline
  let &cursorcolumn = s.cursorcolumn

  unlet g:softwrap_saved
endfunc
