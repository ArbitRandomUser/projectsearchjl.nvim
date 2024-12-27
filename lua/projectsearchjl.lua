local M = {}

--cache to store paths 
--buffer[n] will store a list of paths that files project dep resolves to 
local buffers_cache = {}
local juliabin
local pickers --= require"telescope.pickers"
local finders --= require"telescope.finders"
local make_entry --= require"telescope.make_entry"
local conf --= require"telescope.config".values
local fzflua
local Path = require"fzf-lua.path"
local jlfzfopts = {}

local scriptpath --path of this project finder script , computed in setup



local compute_projectfolders = function(bufno)
    filename = vim.api.nvim_buf_get_name(bufno)
    local on_exit = function(out)
        buffers_cache[bufno] = out.stdout
    end
    fullfilename = vim.fn.expand('%:p')
    obj =vim.system({juliabin,"--startup-file=no", scriptpath ,fullfilename},{text=true},on_exit)
end


M.telescope_live_grep_jl = function (bufno)
    local opts = {}
    local finder =finders.new_async_job{
        command_generator = function(prompt)
            if not prompt or prompt=="" then
                return nil
            end
            local args = {"rg"}
            table.insert(args,"-e")
            table.insert(args,prompt)
            table.insert(args, "-g")
            table.insert(args,"*.jl")
            local command =  vim.iter({args,{"--color=never","--no-heading","--with-filename","--line-number","--column","--smart-case"}}):flatten():totable()
            local depfolders = vim.fn.split(buffers_cache[bufno]," ")
            command = vim.iter({command,depfolders}):flatten():totable()
            return command
        end,
        entry_maker = make_entry.gen_from_vimgrep(opts),
    }
    pickers.new(opts,{
            debounce = 100,
            prompt_title = "julia project search",
            finder = finder,
            previewer =  conf.grep_previewer(opts),
            sorter = require("telescope.sorters").empty(),
        }):find()
end


M.fzflua_live_grep_jl = function (bufno)
    local depfolders = buffers_cache[bufno] 
    fzflua.fzf_live("rg --glob=*.jl --regexp=<query> --column --line-number --no-heading --color=always --smart-case "..depfolders,
        jlfzfopts
    )
end

M.setup = function(opts)
    juliabin = vim.fn.expand(opts.juliabin)
    local paths=vim.api.nvim_list_runtime_paths()
    local pluginpath --path of this plugin
    for _, str in ipairs(paths) do
        if str:match(".*projectsearchjl.nvim$") then
            pluginpath = str
        end
    end
    scriptpath = vim.fs.joinpath(pluginpath,"projectsearch.jl")
    --telescope setup
    if opts.picker == "telescope" then
        pickers = require"telescope.pickers"
        finders = require"telescope.finders"
        make_entry = require"telescope.make_entry"
        conf = require"telescope.config".values
    end
    --fzflua setup
    jlfzfopts = {
        path_shorten = 3,
        previewer = "builtin",
    }
    if opts.picker == "fzf-lua" or opts.picker == "fzflua" then
        fzflua = require"fzf-lua"
        jlfzfopts.fn_transform = function (x)
            return fzflua.make_entry.file(x,jlfzfopts)
        end
        jlfzfopts.prompt="julia project search>"
    end

    --autocmd to resolve source folders
    vim.api.nvim_create_autocmd(
        {"BufEnter"},
        {   pattern ={"*.jl"},
            callback = function(ev)
                compute_projectfolders(vim.api.nvim_get_current_buf())
            end
        }
    )
end

return M
