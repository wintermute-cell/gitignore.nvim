# gitignore.nvim
![gitignore.nvim logo banner](https://github.com/wintermute-cell/gitignore.nvim/blob/resources/_resources/banner.webp)

A neovim plugin for generating .gitignore files in seconds, by allowing you to
select from a huge number of different technologies.

This plugin is functionally identical to the service offered by
[gitignore.io](https://www.toptal.com/developers/gitignore/), but capable of
generating `.gitignore` files offline, and directly from within neovim.

1. [Installation](#installation)
1. [Usage](#usage)
3. [Credits](#credits)

## Installation
`gitignore.nvim` depends on
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)!


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
use {
  "wintermute-cell/gitignore.nvim"
}
```

## Usage
This plugin ships with only one command:
```
:Gitignore
```

Furthermore, you can use the corresponding `lua` function directly, for example
to create a keymap:
```
local gitignore = require("gitignore")
vim.keymap.set("n", "<leader>gi", gitignore.generate)
```


## Credits
Thanks to [Toptal](https://github.com/toptal/gitignore) for providing a huge
list of ignore-templates!
