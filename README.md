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

-- with telescope 
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".telescope_grep_jl()) 
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".telescope_live_grep_jl())


-- fzf-lua bindings
vim.keymap.set('n','<your keybind here',require"projectsearchjl".fzflua_live_grep_jl())
vim.keymap.set('n','<your keybind here>',require"projectsearchjl".fzflua_grep_jl())

-- i also like to pass the visual selection to fzflua 

vim.keymap.set('v', '<your keybind here>', function ()
    query = getVisualSelection()
    require "projectsearchjl".fzflua_grep_jl(query)
end)

vim.keymap.set('v', '<leader>jl', function ()
    query = getVisualSelection()
    require "projectsearchjl".fzflua_live_grep_jl(query)
end)

--where VisualSelection is defined as.
-- get selection for visual selection 
function getVisualSelection()
    vim.cmd('noau normal! "vy"')
    local text = vim.fn.getreg('v')
    vim.fn.setreg('v', {})
    text = string.gsub(text, "\n", "")
    if #text > 0 then
        return text
    else
        return ''
    end
end

-- 
```
<b>grep</b>: prompts you for a string first `search for?` in the nvim command line. That string is then searched for in the project source folders using `rg` and triggers telescope/fzf floating window. Furthur filtering can be done by typing floating window.

<b>live_grep</b>: Pops up telescope/fzflua first, as you start typing neovim will search for the typed string using `rg` in the source folders that the project resolves to. You can switch to grep-mode and filter furthur by `alt-g` (only if using fzflua) . 
