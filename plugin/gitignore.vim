if exists('g:loaded_gitignore')
    finish
endif
lua require'gitignore'
let g:loaded_gitignore = 1
