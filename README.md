# :sparkles: scratch-buffer.vim :sparkles:

:rocket: **No more hassle with file paths!** The fastest way to open an instant scratch buffer.

For both :star:Vim:star: and :star:Neovim:star:.

![](./readme/main.gif)

## Table of Contents

- [:sparkles: scratch-buffer.vim :sparkles:](#sparkles-scratch-buffervim-sparkles)
  - [:wrench: Quick Start](#wrench-quick-start)
  - [:fire: Why scratch-buffer.vim?](#fire-why-scratch-buffervim)
  - [:zap: Supercharge with vim-quickrun!](#zap-supercharge-with-vim-quickrun)
  - [:balance_scale: Comparison with scratch.vim](#balance_scale-comparison-with-scratchvim)
    - [:gear: Detailed Usage](#gear-detailed-usage)
  - [:keyboard: Default Keymappings](#keyboard-default-keymappings)
  - [:sparkles: scratch.vim Compatibility](#sparkles-scratchvim-compatibility)

- - - - -

## :star: Features

- Open temporary buffer by **only a keymap** or a command
- Auto close when you leave the opened buffer
- Auto save when you leave from insert mode in the opened buffer (for file buffers)

![](./readme/main.gif)

- - -

- Open temporary buffer with specified filetype

![](./readme/filetypes.gif)

- - -

- Open multiple buffers with sequential numbering
    - Meaning you can:
        - Write multiple memos with different topics
        - Create a new buffer when needed without deleting the previous one
        - Collect your knowledges

![](./readme/sequencial.gif)

Allright, you can clean them up when you want.

![](./readme/clean.gif)

- - -

And more features...

## :wrench: Quick Start

```vim
:ScratchBufferOpen  " Open a temporary buffer using default options
:ScratchBufferOpen md sp 5  " Open a temporary Markdown buffer with :sp and height 5
:ScratchBufferOpenFile ts vsp 100  " Open a persistent TypeScript buffer with :vsp and width 100
:ScratchBufferOpenNext  " Open next temporary buffer
:ScratchBufferOpenFileNext  " Open next persistent buffer
```

Please see '[Detailed Usage](#gear-detailed-usage)' section for more information.

## :fire: Why scratch-buffer.vim?

- **Open instantly!** Just run `:ScratchBufferOpen`!
- **No file management!** Perfect for quick notes and testing code snippets.
- **Works anywhere!** Whether in terminal Vim or GUI, it's always at your fingertips.

## :zap: Supercharge with vim-quickrun!

:bulb: **Combine it with [vim-quickrun](https://github.com/thinca/vim-quickrun) to execute code instantly!**

```vim
" Write TypeScript code...
:ScratchBufferOpen ts

" ...and run it immediately!
:QuickRun
```

## :balance_scale: Comparison with scratch.vim

[scratch.vim](https://github.com/mtth/scratch.vim) is a great plugin.
However, vim-scratch-buffer adds more features.

Compared to scratch.vim, vim-scratch-buffer provides these additional features:

- Flexible buffer management
    - Open multiple buffers with sequential numbering (`:ScratchBufferOpenNext`)
    - Quick access to recently used buffers (`:ScratchBufferOpen`)
    - When you want to take notes on different topics, scratch.vim only allows one buffer
    - See `:help :ScratchBufferOpen` and `:help :ScratchBufferOpenNext`

- Buffer type options
    - Choose between writeable buffers or temporary buffers
    - Automatic saving for file buffers when enabled
    - Convert temporary buffers to persistent ones when needed
    - See `:help :ScratchBufferOpen` and `:help :ScratchBufferOpenFile`

- Customization options
    - Specify filetype for syntax highlighting, for `:QuickRun`, and for etc
    - Choose opening method (`:split` or `:vsplit`)
    - Control buffer height/width
    - Configurable auto-hiding behavior: [scratch.vim compatibility](#sparkles-scratchvim-compatibility)
    - Customize buffer file locations:
      ```vim
      " Configure different paths for temporary and persistent buffers
      let g:scratch_buffer_file_pattern = #{
        \ when_tmp_buffer: '/tmp/scratch-tmp-%d',      " For :ScratchBufferOpen
        \ when_file_buffer: expand('~/scratch/%d'),    " For :ScratchBufferOpenFile
      \ }
      " This is useful if you want to keep a file buffer directory
      " (`~/tmp` in the above case) with `.prettier`, etc.
      ```

Please also see [doc/vim-scratch-buffer.txt](./doc/vim-scratch-buffer.txt) for other functions.

### :gear: Detailed Usage

```vim
" Basic Usage

" Open a temporary buffer using default settings
:ScratchBufferOpen

" Same as :ScratchBufferOpen but opens a writable persistent buffer
:ScratchBufferOpenFile
```

```vim
" Open a new scratch buffer with a specific filetype

" Example: Markdown
:ScratchBufferOpen md

" Example: TypeScript
:ScratchBufferOpen ts

" Example: No filetype
:ScratchBufferOpen --no-file-ext
```

```vim
" Open multiple scratch buffers
:ScratchBufferOpen md      " Opens most recently used buffer
:ScratchBufferOpenNext md  " Always creates a new buffer
```

```vim
" Open a small buffer at the top for quick notes
:ScratchBufferOpen md sp 5
:ScratchBufferOpen --no-file-ext sp 5
```

```vim
" Delete all scratch files and buffers
:ScratchBufferClean
```

Please also see [doc/vim-scratch-buffer.txt](./doc/vim-scratch-buffer.txt) for other usage.

## :keyboard: Default Keymappings

When `g:scratch_buffer_use_default_keymappings` is enabled (default: `v:false`), the following keymappings are available:

```vim
" Quick open commands (execute immediately)
nnoremap <silent> <leader>b <Cmd>ScratchBufferOpen<CR>
nnoremap <silent> <leader>B <Cmd>ScratchBufferOpenFile<CR>

" Interactive commands (allows adding arguments)
nnoremap <leader><leader>b :<C-u>ScratchBufferOpen<Space>
nnoremap <leader><leader>B :<C-u>ScratchBufferOpenFile<Space>
```

The quick open commands create buffers with default settings, while the interactive commands let you specify file extension, open method, and buffer size.

You can customize these mappings by disabling the defaults:

```vim
let g:scratch_buffer_use_default_keymappings = v:false
```

And then defining your own:

```vim
" Example custom mappings
nnoremap <silent> <leader>s <Cmd>ScratchBufferOpen<CR>
nnoremap <silent> <leader>S <Cmd>ScratchBufferOpenFile<CR>
```

## :sparkles: scratch.vim compatibility

To make the plugin behave like scratch.vim, you can enable automatic buffer hiding!
When enabled, scratch buffers will automatically hide when you leave the window.
You can configure this behavior separately for temporary buffers and file buffers.

Enable both types of buffer hiding with:

```vim
let g:scratch_buffer_auto_hide_buffer = #{
  \ when_tmp_buffer: v:true,
  \ when_file_buffer: v:true,
\ }
```

Or enable hiding for only temporary buffers:

```vim
let g:scratch_buffer_auto_hide_buffer = #{ when_tmp_buffer: v:true }
```

Or enable hiding for only file buffers:

```vim
let g:scratch_buffer_auto_hide_buffer = #{ when_file_buffer: v:true }
```
