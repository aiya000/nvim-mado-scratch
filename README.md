**CURRENTLY WIP**

# :sparkles: mado-scratch-buffer.nvim :sparkles:

:rocket: **No more hassle with file paths!** The fastest way to open an instant scratch buffer.

For :star:Neovim:star: (lua-based modern implementation).

![](./readme/main.gif)

## Table of Contents

- [:sparkles: mado-scratch-buffer.nvim :sparkles:](#sparkles-mado-scratch-buffernvim-sparkles)
  - [:gear: Installation](#gear-installation)
  - [:wrench: Configuration](#wrench-configuration)
  - [:wrench: Quick Start](#wrench-quick-start)
  - [:fire: Why mado-scratch-buffer.nvim?](#fire-why-mado-scratch-buffernvim)
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

## :gear: Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'aiya000/mado-scratch-buffer.nvim',
  config = function()
    require('scratch-buffer').setup({
      -- Optional configuration (these are defaults)
      file_pattern = {
        when_tmp_buffer = '/tmp/mado-scratch-tmp-%d',
        when_file_buffer = '/tmp/mado-scratch-file-%d',
      },
      default_file_ext = 'md',
      default_open_method = 'sp',
      default_buffer_size = 15,
      auto_save_file_buffer = true,
      use_default_keymappings = false,  -- Set to true to enable default keymaps
      auto_hide_buffer = {
        when_tmp_buffer = false,
        when_file_buffer = false,
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'aiya000/mado-scratch-buffer.nvim',
  config = function()
    require('scratch-buffer').setup()
  end
}
```

## :wrench: Configuration

The plugin works out of the box with sensible defaults, but you can customize it:

```lua
require('scratch-buffer').setup({
  -- File patterns for temporary and persistent buffers
  file_pattern = {
    when_tmp_buffer = '/tmp/mado-scratch-tmp-%d',      -- For :MadoScratchBufferOpen
    when_file_buffer = vim.fn.expand('~/scratch/%d'), -- For :MadoScratchBufferOpenFile
  },

  -- Default settings
  default_file_ext = 'md',           -- Default file extension
  default_open_method = 'sp',        -- 'sp' or 'vsp'
  default_buffer_size = 15,          -- Default buffer height/width

  -- Behavior options
  auto_save_file_buffer = true,      -- Auto-save file buffers on TextChanged
  use_default_keymappings = true,    -- Enable default keymaps

  -- Auto-hide settings (like scratch.vim)
  auto_hide_buffer = {
    when_tmp_buffer = false,         -- Auto-hide temporary buffers
    when_file_buffer = false,        -- Auto-hide persistent buffers
  },
})
```

## :wrench: Quick Start

```vim
:MadoScratchBufferOpen  " Open a temporary buffer using default options
:MadoScratchBufferOpen md sp 5  " Open a temporary Markdown buffer with :sp and height 5
:MadoScratchBufferOpenFile ts vsp 100  " Open a persistent TypeScript buffer with :vsp and width 100
:MadoScratchBufferOpenNext  " Open next temporary buffer
:MadoScratchBufferOpenFileNext  " Open next persistent buffer
```

Please see '[Detailed Usage](#gear-detailed-usage)' section for more information.

## :fire: Why mado-scratch-buffer.nvim?

- **Open instantly!** Just run `:MadoScratchBufferOpen`!
- **No file management!** Perfect for quick notes and testing code snippets.
- **Works anywhere!** Whether in terminal Vim or GUI, it's always at your fingertips.

## :zap: Supercharge with vim-quickrun!

:bulb: **Combine it with [vim-quickrun](https://github.com/thinca/vim-quickrun) to execute code instantly!**

```vim
" Write TypeScript code...
:MadoScratchBufferOpen ts

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
      ```lua
      -- Configure different paths for temporary and persistent buffers
      require('scratch-buffer').setup({
        file_pattern = {
          when_tmp_buffer = '/tmp/mado-scratch-tmp-%d',      -- For :MadoScratchBufferOpen
          when_file_buffer = vim.fn.expand('~/scratch/%d'), -- For :MadoScratchBufferOpenFile
        }
      })
      -- This is useful if you want to keep a file buffer directory
      -- (`~/scratch` in the above case) with `.prettier`, etc.
      ```

Please also see [doc/mado-scratch-buffer.txt](./doc/mado-scratch-buffer.txt) for other functions.

### :gear: Detailed Usage

```vim
" Basic Usage

" Open a temporary buffer using default settings
:MadoScratchBufferOpen

" Same as :MadoScratchBufferOpen but opens a writable persistent buffer
:MadoScratchBufferOpenFile
```

```vim
" Open a new scratch buffer with a specific filetype

" Example: Markdown
:MadoScratchBufferOpen md

" Example: TypeScript
:MadoScratchBufferOpen ts

" Example: No filetype
:MadoScratchBufferOpen --no-file-ext
```

```vim
" Open multiple scratch buffers
:MadoScratchBufferOpen md      " Opens most recently used buffer
:MadoScratchBufferOpenNext md  " Always creates a new buffer
```

```vim
" Open a small buffer at the top for quick notes
:MadoScratchBufferOpen md sp 5
:MadoScratchBufferOpen --no-file-ext sp 5
```

```vim
" Delete all scratch files and buffers
:MadoScratchBufferClean
```

Please also see [doc/mado-scratch-buffer.txt](./doc/mado-scratch-buffer.txt) for other usage.

## :keyboard: Default Keymappings

When `use_default_keymappings` is enabled in setup (default: `false`), the following keymappings are available:

```lua
-- Enable default keymappings
require('scratch-buffer').setup({
  use_default_keymappings = true,
})
```

The keymappings:
```vim
" Quick open commands (execute immediately)
<leader>b       → :MadoScratchBufferOpen
<leader>B       → :MadoScratchBufferOpenFile

" Interactive commands (allows adding arguments)
<leader><leader>b  → :MadoScratchBufferOpen (with cursor ready for arguments)
<leader><leader>B  → :MadoScratchBufferOpenFile (with cursor ready for arguments)
```

The quick open commands create buffers with default settings, while the interactive commands let you specify file extension, open method, and buffer size.

You can also define your own custom mappings:

```lua
-- Example custom mappings
vim.keymap.set('n', '<leader>s', '<Cmd>MadoScratchBufferOpen<CR>', { silent = true })
vim.keymap.set('n', '<leader>S', '<Cmd>MadoScratchBufferOpenFile<CR>', { silent = true })
```

## :sparkles: scratch.vim compatibility

To make the plugin behave like scratch.vim, you can enable automatic buffer hiding!
When enabled, scratch buffers will automatically hide when you leave the window.
You can configure this behavior separately for temporary buffers and file buffers.

Enable both types of buffer hiding with:

```lua
require('scratch-buffer').setup({
  auto_hide_buffer = {
    when_tmp_buffer = true,
    when_file_buffer = true,
  },
})
```

Or enable hiding for only temporary buffers:

```lua
require('scratch-buffer').setup({
  auto_hide_buffer = {
    when_tmp_buffer = true,
  },
})
```

Or enable hiding for only file buffers:

```lua
require('scratch-buffer').setup({
  auto_hide_buffer = {
    when_file_buffer = true,
  },
})
```
