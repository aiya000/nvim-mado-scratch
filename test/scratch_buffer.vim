const s:suite = themis#suite('scratch_buffer')
const s:expect = themis#helper('expect')
const s:assert = themis#helper('assert')

function! s:suite.before() abort
  " Backup default values
  let g:backup_scratch_buffer_default_file_ext = g:scratch_buffer_default_file_ext
  let g:backup_scratch_buffer_default_open_method = g:scratch_buffer_default_open_method
  let g:backup_scratch_buffer_default_buffer_size = g:scratch_buffer_default_buffer_size
  let g:backup_scratch_buffer_auto_save_file_buffer = g:scratch_buffer_auto_save_file_buffer
  let g:backup_scratch_buffer_use_default_keymappings = g:scratch_buffer_use_default_keymappings
  let g:backup_scratch_buffer_auto_hide_buffer = g:scratch_buffer_auto_hide_buffer
  let g:backup_scratch_buffer_file_pattern = g:scratch_buffer_file_pattern
endfunction

function! s:suite.before_each() abort
  " Don't waste our environment
  let g:scratch_buffer_file_pattern = #{
    \ when_tmp_buffer: fnamemodify('./test/tmp/scratch-tmp-%d', ':p'),
    \ when_file_buffer: fnamemodify('./test/tmp/scratch-file-%d', ':p'),
  \ }
  " Restore default values
  let g:scratch_buffer_default_file_ext = g:backup_scratch_buffer_default_file_ext
  let g:scratch_buffer_default_open_method = g:backup_scratch_buffer_default_open_method
  let g:scratch_buffer_default_buffer_size = g:backup_scratch_buffer_default_buffer_size
  let g:scratch_buffer_auto_save_file_buffer = g:backup_scratch_buffer_auto_save_file_buffer
  let g:scratch_buffer_use_default_keymappings=g:backup_scratch_buffer_use_default_keymappings
  let g:scratch_buffer_auto_hide_buffer = g:backup_scratch_buffer_auto_hide_buffer

  " Clean all created scratch files and buffers
  ScratchBufferClean

  " Close opened windows
  new
  only
endfunction

function! s:suite.after_each() abort
  " Clean all created files
  for file in glob(g:scratch_buffer_file_pattern.when_tmp_buffer[:-3] .. '*', v:false, v:true)
    call delete(file)
  endfor
  for file in glob(g:scratch_buffer_file_pattern.when_file_buffer[:-3] .. '*', v:false, v:true)
    call delete(file)
  endfor
endfunction

function! s:suite.ScratchBufferOpen_shoud_can_make_buffer() abort
  ScratchBufferOpen
  const file_name = expand('%:p')
  const expected = printf(g:scratch_buffer_file_pattern.when_tmp_buffer, 0) .. '.md'
  call s:expect(file_name).to_equal(expected)
endfunction

function! s:suite.ScratchBufferOpenNext_can_make_multiple_buffer() abort
  ScratchBufferOpen
  const main_file = expand('%:p')
  ScratchBufferOpenNext
  const next_file = expand('%:p')
  call s:expect(main_file).not.to_equal(next_file)
endfunction

function! s:suite.ScratchBufferOpen_should_open_recent_buffer_after_ScratchBufferOpenNext() abort
  ScratchBufferOpenNext
  const first_file = expand('%:p')

  " Move to a different window
  new

  ScratchBufferOpen
  const second_file = expand('%:p')

  call s:expect(second_file).to_equal(first_file)
endfunction

function! s:suite.MadoScratchBufferOpenNext_should_create_third_buffer() abort
  " Test for issue #5: Cannot create 3rd buffer
  MadoScratchBufferOpen
  const file1 = expand('%:p')
  const expected1 = printf(g:scratch_buffer_file_pattern.when_tmp_buffer, 0) .. '.md'
  call s:expect(file1).to_equal(expected1)

  MadoScratchBufferOpenNext
  const file2 = expand('%:p')
  const expected2 = printf(g:scratch_buffer_file_pattern.when_tmp_buffer, 1) .. '.md'
  call s:expect(file2).to_equal(expected2)
  call s:expect(file2).not.to_equal(file1)

  MadoScratchBufferOpenNext
  const file3 = expand('%:p')
  const expected3 = printf(g:scratch_buffer_file_pattern.when_tmp_buffer, 2) .. '.md'
  call s:expect(file3).to_equal(expected3)
  call s:expect(file3).not.to_equal(file2)
  call s:expect(file3).not.to_equal(file1)
endfunction

function! s:is_scratch_buffer_open_buffer_writable() abort
  let is_written = v:false
  try
    ScratchBufferOpen
    write
    let is_written = v:true
  catch
  endtry
  return is_written
endfunction

function! s:suite.ScratchBufferOpen_should_open_readonly_file() abort
  call s:expect(s:is_scratch_buffer_open_buffer_writable()).to_equal(v:false)
endfunction

" Try to :write a file opened by ScratchBufferOpenFile.
" @returns {boolean} - the opened file is writable
function! s:is_scratch_buffer_open_file_buffer_writable() abort
  let is_written = v:false
  try
    ScratchBufferOpenFile
    write
    let is_written = v:true
  catch
  endtry
  return is_written
endfunction

function! s:suite.ScratchBufferOpenFile_should_open_writable_file() abort
  call s:expect(s:is_scratch_buffer_open_file_buffer_writable()).to_equal(v:true)
endfunction

function! s:suite.ScratchBufferClean_should_wipe_opened_files_and_buffers() abort
  ScratchBufferOpenFile md
  const first_file = expand('%:p')
  write
  ScratchBufferOpen md
  const second_file = expand('%:p')

  " Check the created files stil exist
  const all_buffer_names = scratch_buffer#helper#get_all_buffer_names()
  call s:expect(filereadable(first_file)).to_be_same(1)
  call s:expect(
    \ all_buffer_names->scratch_buffer#helper#contains(first_file),
  \ ).not.to_equal(-1)
  call s:expect(
   \ all_buffer_names->scratch_buffer#helper#contains(second_file),
  \ ).not.to_equal(-1)

  " Wipe all scratch buffers and files
  ScratchBufferClean

  " Check the created files are removed
  const new_all_buffer_names = scratch_buffer#helper#get_all_buffer_names()
  call s:expect(filereadable(first_file)).not.to_be_same(1)
  call s:expect(
    \ new_all_buffer_names->scratch_buffer#helper#contains(first_file),
  \ ).not.to_equal(-1)
  call s:expect(
    \ new_all_buffer_names->scratch_buffer#helper#contains(second_file),
  \ ).not.to_equal(-1)
endfunction

function! s:suite.ScratchBufferOpen_should_accept_file_extension() abort
  ScratchBufferOpen md
endfunction

function! s:suite.ScratchBufferOpen_should_accept_open_method() abort
  ScratchBufferOpen md sp
  ScratchBufferOpen md vsp
endfunction

function! s:suite.ScratchBufferOpen_should_accept_buffer_size() abort
  ScratchBufferOpen md sp 5
  ScratchBufferOpen md vsp 50
endfunction

function! s:suite.ScratchBufferOpen_should_use_default_values() abort
  let g:scratch_buffer_default_file_ext = 'ts'
  let g:scratch_buffer_default_open_method = 'vsp'
  let g:scratch_buffer_default_buffer_size = 20

  " Open another window to resize a scratch buffer
  new
  " Open buffer without arguments
  ScratchBufferOpen

  const file_name = expand('%:p')
  const expected = printf(g:scratch_buffer_file_pattern.when_tmp_buffer, 0) .. '.ts'
  call s:expect(file_name).to_equal(expected)
  call s:expect(winwidth(0)).to_be_same(20)
endfunction

function! s:suite.ScratchBufferOpen_should_support_auto_saving_file_buffer() abort
  let g:scratch_buffer_auto_save_file_buffer = v:true
  ScratchBufferOpenFile md
  call setline(1, 'test content')
  doautocmd TextChanged

  const file_name = expand('%:p')
  call s:expect(filereadable(file_name)).to_be_same(1)
  call s:expect(readfile(file_name)[0]).to_equal('test content')
endfunction

function! s:suite.ScratchBufferOpen_should_support_auto_hiding_tmp_buffer() abort
  let g:scratch_buffer_auto_hide_buffer = #{
    \ when_tmp_buffer: v:true,
    \ when_file_buffer: v:true,
  \ }

  ScratchBufferOpen md
  wincmd p  " Trigger WinLeave
  call s:expect(winnr('$')).to_be_same(1)
endfunction

function! s:suite.ScratchBufferOpen_should_support_auto_hiding_file_buffer() abort
  let g:scratch_buffer_auto_hide_buffer = #{
    \ when_tmp_buffer: v:true,
    \ when_file_buffer: v:true,
  \ }

  ScratchBufferOpenFile md
  wincmd p  " Trigger WinLeave
  call s:expect(winnr('$')).to_be_same(1)
endfunction

function! s:suite.ScratchBufferOpen_should_use_when_tmp_buffer_pattern() abort
  let g:scratch_buffer_file_pattern = #{
    \ when_tmp_buffer: fnamemodify('./test/tmp/scratch-tmp-%d', ':p'),
    \ when_file_buffer: 'not specified',
  \ }

  ScratchBufferOpen
  const file_name = expand('%:p')
  const expected = printf(g:scratch_buffer_file_pattern.when_tmp_buffer, 0) .. '.md'
  call s:expect(file_name).to_equal(expected)
endfunction

function! s:suite.ScratchBufferOpenFile_should_use_when_file_buffer_pattern() abort
  let g:scratch_buffer_file_pattern = #{
    \ when_tmp_buffer: 'not specified',
    \ when_file_buffer: fnamemodify('./test/tmp/scratch-file-%d', ':p'),
  \ }

  ScratchBufferOpenFile
  const file_name = expand('%:p')
  const expected = printf(g:scratch_buffer_file_pattern.when_file_buffer, 0) .. '.md'
  call s:expect(file_name).to_equal(expected)
endfunction

function! s:suite.ScratchBufferOpen_and_ScratchBufferOpenFile_should_make_different_buffers_when_options_is_different() abort
  let g:scratch_buffer_file_pattern = #{
    \ when_tmp_buffer: fnamemodify('./test/tmp/scratch-tmp-%d', ':p'),
    \ when_file_buffer: fnamemodify('./test/tmp/scratch-file-%d', ':p'),
  \ }

  ScratchBufferOpen
  const tmp_file = expand('%:p')
  ScratchBufferOpenFile
  const persistent_file = expand('%:p')
  call s:expect(tmp_file).not.to_equal(persistent_file)
endfunction

function! s:is_current_buffer_type_tmp() abort
  return &buftype ==# 'nofile' && &bufhidden ==# 'hide'
endfunction

function! s:is_current_buffer_type_file() abort
  return &buftype ==# '' && &bufhidden ==# ''
endfunction

function! s:suite.ScratchBufferOpenFile_should_change_the_previous_buffer_type_of_the_tmp_buffer_to_file_buffer_if_file_pattern_is_same() abort
  const file_pattern = fnamemodify('./test/tmp/scratch-%d', ':p')
  let g:scratch_buffer_file_pattern = #{
    \ when_tmp_buffer: file_pattern,
    \ when_file_buffer: file_pattern,
  \ }

  ScratchBufferOpen
  const first_file = expand('%:p')

  ScratchBufferOpenFile
  const second_file = expand('%:p')

  call s:expect(first_file).to_equal(second_file)
  call s:expect(s:is_current_buffer_type_file()).to_be_same(1)
endfunction

function! s:suite.ScratchBufferOpen_should_change_the_buffer_type_of_the_previous_file_buffer_to_tmp_buffer_if_file_pattern_is_same() abort
  const file_pattern = fnamemodify('./test/tmp/scratch-%d', ':p')
  let g:scratch_buffer_file_pattern = #{
    \ when_tmp_buffer: file_pattern,
    \ when_file_buffer: file_pattern,
  \ }

  ScratchBufferOpenFile
  const first_file = expand('%:p')

  ScratchBufferOpen
  const second_file = expand('%:p')

  call s:expect(first_file).to_equal(second_file)
  call s:expect(s:is_current_buffer_type_tmp()).to_be_same(1)
endfunction

