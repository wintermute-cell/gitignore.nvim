<!-- LTeX: language=en-US -->
# gitignore.nvim
![gitignore.nvim logo banner](https://github.com/wintermute-cell/gitignore.nvim/blob/resources/_resources/banner.webp)

A neovim plugin for generating .gitignore files in seconds, by allowing you to
select from a huge number of different technologies.

This plugin is functionally identical to the service offered by
[gitignore.io](https://www.toptal.com/developers/gitignore/), but capable of
generating `.gitignore` files offline, and directly from within neovim.

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png)](https://www.buymeacoffee.com/winterv)

1. [Installation](#installation--dependencies)
2. [Usage](#usage)
3. [Demo](#demo)
4. [Credits](#credits)

## Installation & Dependencies
**`gitignore.nvim` depends on
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), 
please [install](https://github.com/nvim-telescope/telescope.nvim#installation) that plugin first!**

After installing `telescope.nvim`, you can install `gitignore.nvim` like this:

Using [vim-plug](https://github.com/junegunn/vim-plug):
```viml
Plug 'wintermute-cell/gitignore.nvim'
```

Using [dein](https://github.com/Shougo/dein.vim):
```viml
call dein#add("wintermute-cell/gitignore.nvim")
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use({
     "wintermute-cell/gitignore.nvim",
     requires = {
        "nvim-telescope/telescope.nvim"
     }
})
```

## Usage
This plugin ships with only one command which when run,
it will create a buffer with the `.gitignore` contents:
```
:Gitignore [path]
```
If an existing `.gitignore` is found, the generated contents will be appended
to the existing lines. The buffer will not save automatically, so there is no
risk of overwriting an existing `.gitignore`.

You can **optionally** pass a `path` argument to point the command to a
specific directory (for example if you have nested `.gitignore` files).

Alternatively, you can use the corresponding `lua` function directly, for
example to create a keymap:
```lua
local gitignore = require("gitignore")
vim.keymap.set("n", "<leader>gi", gitignore.generate)
```

Or with a path:
```lua
local gitignore = require("gitignore")
local my_path = "./some/path"
vim.keymap.set("n", "<leader>gi", 
    function ()
        gitignore.generate(my_path)
    end
)
```

### Selecting multiple items
`gitignore.nvim` makes use of `telescope.nvim`'s multi-selection keybinds. 
This means that by default, you can (de-)select multiple keywords with `<Tab>`,
and confirm your selection with `<CR>` (Enter).
In case of multiple selected keywords, the keyword highlighted you press `<CR>`
on will **not** be added to the selection!

For convenience, when no multi-selection is made before pressing `<CR>`,
`<CR>` will actually add the highlighted item to the selection, and create
a `.gitignore` file for the single keyword.

## Configuration
If you want the `:Gitignore` command to overwrite your current `.gitignore`
instead of appending to it, you can set:
```lua
vim.g.gitignore_nvim_overwrite = true
```
If this variable is set to `false`, or not set at all, `:Gitignore` will take
into account an existing gitignore.

## Demo
[![asciicast](https://asciinema.org/a/GOHXDt4kYsR8pzrxTEOIridTf.svg)](https://asciinema.org/a/GOHXDt4kYsR8pzrxTEOIridTf)

## Credits
Thanks to [Toptal](https://github.com/toptal/gitignore) for providing a huge
list of ignore-templates!
