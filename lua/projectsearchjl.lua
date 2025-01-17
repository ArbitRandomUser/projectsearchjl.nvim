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
local jlfzfopts = {}
local fzfactions 
local fzfconfig  
local fzfcore


local scriptpath --path of this project finder script , computed in setup



local compute_projectfolders = function(bufno)
    filename = vim.api.nvim_buf_get_name(bufno)
    local on_exit = function(out)
        buffers_cache[bufno] = out.stdout
    end
    fullfilename = vim.fn.expand('%:p')
    obj =vim.system({juliabin,"--startup-file=no", scriptpath ,fullfilename},{text=true},on_exit)
end


M.telescope_live_grep_jl = function (opts)
    opts = opts or {}
    local bufno = vim.api.nvim_get_current_buf()
    local depfolders = vim.fn.split(buffers_cache[bufno]," ")
    if not depfolders then
        print("oops! caching not finished try again, either that or this isn't a *.jl")
        return
    end
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
            command = vim.iter({command,depfolders}):flatten():totable()
            return command
        end,
        entry_maker = make_entry.gen_from_vimgrep(opts),
    }
    pickers.new(opts,{
            debounce = 100,
            prompt_title = "julia live grep",
            finder = finder,
            previewer =  conf.grep_previewer(opts),
            sorter = require("telescope.sorters").empty(),
        }):find()
end

M.telescope_grep_jl = function (opts)
    opts = opts or {}
    local bufno = vim.api.nvim_get_current_buf()
    local depfolders = vim.fn.split(buffers_cache[bufno]," ")
    if not depfolders then
        print("oops! caching not finished try again, either that or this isn't a *.jl")
        return
    end
    local searchstring = vim.fn.input("search for?")
    local commandopts = {"rg", "-e" , searchstring, "--glob=*.jl" ,"--color=never","--no-heading","--with-filename","--column","--smart-case"}
    local command = vim.iter({commandopts,depfolders}):flatten():totable() 
    opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
    local finder = finders.new_oneshot_job(command ,opts)
    pickers.new(opts,{
            debounce=100,
            prompt_title = "julia grep",
            finder = finder,
            previewer = conf.grep_previewer(opts),
            sorter = conf.generic_sorter(opts),
        }):find()
end

M.fzflua_live_grep_jl = function(query)
    local opts = fzfconfig.normalize_opts(opts,"grep") 
    local bufno = vim.api.nvim_get_current_buf()
    local depfolders = buffers_cache[bufno] 
    if not depfolders then
        print("oops! caching not finished try again, either that or this isn't a *.jl")
        return
    end
    query = query or ""
    opts.query = query
    opts.prompt = "julia live grep>"
    --opts.actions = {["ctrl-g"] = function (_,opts)
    --    M.fzflua_grep_jl(opts.last_query)
    --end}
    M.fzf_live("rg --glob=*.jl --regexp=<query> --column --line-number --no-heading --color=always --smart-case "..depfolders,
        opts
    )
end


M.fzf_live = function(contents, opts)
  assert(contents)
  opts = fzfconfig.normalize_opts(opts, "grep")
  opts = opts or {}
  opts.fn_reload = contents
  search_query = search_query or ""
  if #search_query > 0 and not (no_esc or opts.no_esc) then
    -- For UI consistency, replace the saved search query with the regex
    opts.no_esc = true
    opts.search = utils.rg_escape(search_query)
    search_query = opts.search
  end
  opts.actions["alt-g"] = function(_,opts) 
      M.fzflua_grep_jl(opts.last_query)
  end
  opts.actions["ctrl-g"] = function () end
  opts = fzfcore.set_header(opts, opts.headers or { "actions", "cwd" })
  opts = fzfcore.set_fzf_field_index(opts)
  return fzfcore.fzf_exec(nil, opts)
end


M.fzflua_grep_jl = function (grepstring)
    local opts = fzfconfig.normalize_opts(opts,"grep") 
    local bufno = vim.api.nvim_get_current_buf()
    local depfolders = buffers_cache[bufno] 
    opts.prompt = "julia grep>"
    opts.actions["alt-g"] = function(_,opts) 
        M.fzflua_grep_jl(opts.last_query)
    end
    opts.actions["ctrl-g"] = function () end
    if not grepstring then
        grepstring = vim.fn.input("search for?")
    end
    fzflua.fzf_exec("rg --glob=*.jl --regexp="..grepstring.." --column --line-number --no-heading --color=always --smart-case "..depfolders,
        opts
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
    if opts.picker == "fzf-lua" or opts.picker == "fzflua" then
        fzfactions = require"fzf-lua.actions"
        fzfconfig  = require"fzf-lua.config"
        fzflua = require"fzf-lua"
        fzfcore = require"fzf-lua.core"
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
