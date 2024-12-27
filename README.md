A project to search through dependencies source of the current julia project in nvim 

```lua
require("projectsearchjl").setup(
    {juliabin="/home/<user>/.juliaup/bin/julia",
    picker = "fzflua"} -- or "telescope" whichever you use
    )

vim.keymap.set('n','',projectsearchjl.fzflua_live_grep_jl(vim.api.nvim_get_current_buf())
--or--
vim.keymap.set('n','',projectsearchjl.telescope_live_grep_jl(vim.api.nvim_get_current_buf())
```
