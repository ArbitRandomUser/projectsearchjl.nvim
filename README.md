A plugin to search through dependencies source of the current julia project in nvim 

looks up the file's project folder, resolvs where the dependencies are and caches them

use `telescope` or `fzf-lua` to search through julia source files in these directories.

requires:
    `rg` in path

setup:
```lua
require("projectsearchjl").setup(
    {juliabin="/home/<user>/.juliaup/bin/julia",
    picker = "fzflua"} -- or "telescope" whichever you use
    )

-- live grep bindings
vim.keymap.set('n','<your keybind here',require"projectsearchjl".fzflua_live_grep_jl()
--or--
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".telescope_live_grep_jl()


-- grep bindings

vim.keymap.set('n','<your keybind here>',require"projectsearchjl".fzflua_grep_jl())
-- 
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".telescope_grep_jl()) --TODO, not yet implemented
-- 
```
TODO: grep for telescope

grep: prompts you for a string first `search for?` in the nvim command line. That string is then searched for in the project source folders using `rg`. Furthur filtering can be done by typing a string in poped up floating window.

live_grep: give you a prompt, as you start typing neovim will search for typed string using `rg` in the source folders that the project resolves to. You can switch to grep-mode and filter furthur by `ctrl-g` . 
