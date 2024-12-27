A plugin to search through dependencies source of the current julia project in nvim 

looks up the file's project folder, resolvs where the dependencies are and caches them

use `telescope` or `fzf-lua` to search through julia source files in these directories.

setup:
```lua
require("projectsearchjl").setup(
    {juliabin="/home/<user>/.juliaup/bin/julia",
    picker = "fzflua"} -- or "telescope" whichever you use
    )

vim.keymap.set('n','<your keybind here',require"projectsearchjl".fzflua_live_grep_jl(vim.api.nvim_get_current_buf())
--or--
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".telescope_live_grep_jl(vim.api.nvim_get_current_buf())
```
