A plugin to search through dependency source files of the current julia project in nvim.
Looks up the file's project folder for its Project.toml and Manifest.toml, resolves where the dependencies are and caches them

Use `telescope` or `fzf-lua` to search through julia source files in these directories.

#### Requires:
* `rg` in path
*  either [telescope](https://github.com/nvim-telescope/telescope.nvim) or [fzf-lua](https://github.com/ibhagwan/fzf-lua) installed

#### Installation:
Use your neovim plugin manager
ex for Plug:
 ```
 Plug 'ArbitRandomUser/projectsearchjl.nvim'
 ```

#### Setup:

```lua
require("projectsearchjl").setup(
    {juliabin="/home/<user>/.juliaup/bin/julia",
    picker = "fzflua"} -- or "telescope" whichever you use
    )

-- live grep bindings
vim.keymap.set('n','<your keybind here',require"projectsearchjl".fzflua_live_grep_jl())
--or--
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".telescope_live_grep_jl())


-- grep bindings

vim.keymap.set('n','<your keybind here>',require"projectsearchjl".fzflua_grep_jl())
-- 
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".telescope_grep_jl()) 
-- 
```
<b>grep</b>: prompts you for a string first `search for?` in the nvim command line. That string is then searched for in the project source folders using `rg` and triggers telescope/fzf floating window. Furthur filtering can be done by typing floating window.

<b>live_grep</b>: Pops up telescope/fzflua first, as you start typing neovim will search for the typed string using `rg` in the source folders that the project resolves to. You can switch to grep-mode and filter furthur by `ctrl-g` (only if using fzflua) . 
