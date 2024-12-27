"""
    used in find_installed,
    stolen from Pkg.jl
"""
function depots1(depotpath)
    d = depotpath
    isempty(d) && throw("no depots found in DEPOT_PATH")
    return d[1]
end

stdlib_dir() = begin
    normpath(joinpath(Sys.BINDIR::String, "..", "share", "julia", "stdlib", "v$(VERSION.major).$(VERSION.minor)"))
end

stdlib_path(stdlib::String) = joinpath(stdlib_dir(), stdlib)

"""
    traverse up the files path,first folder with Project.toml is assumed to be project folder
    get all Project.toml entries in the format
    (name,uuid,sha1/path,:devpkg/:pkg/:stdlib)
    if filepath or P
"""
function get_project_of_file(filepath)
    #isfile(filepath) || return Dict("deps"=>Dict())
    dir = dirname(filepath)
    while !isfile(joinpath(dir, "Project.toml")) && dir != "/"
        dir = dirname(dir)
    end
    fname = joinpath(dir, "Project.toml")
    isfile(fname) || return Dict("deps" => Dict())
    ret = Base.parsed_toml(fname)
    return ret
end

"""
    like get_project_of_file but for Manifest.toml
"""
function get_manifest_of_file(filepath)
    #isfile(filepath) || return Dict("deps"=>Dict())
    dir = dirname(filepath)
    while !isfile(joinpath(dir, "Project.toml")) && dir != "/"
        dir = dirname(dir)
    end
    fname = joinpath(dir, "Manifest.toml")
    isfile(fname) || return Dict("deps" => Dict())
    ret = Base.parsed_toml(fname)
    return ret
end

function get_slugtuples(filename)
    proj = get_project_of_file(filename)
    manif = get_manifest_of_file(filename)
    slugtuples = Tuple{String,String,String,Symbol}[]
    for (proj, uuid) in proj["deps"]
        manifdeps = manif["deps"][proj]
        manifdep = matchdep(manifdeps, uuid)
        if "path" in keys(manifdep) #deved package
            push!(slugtuples,
                (proj, manifdep["uuid"], manifdep["path"], :devpkg)
            )
        elseif "git-tree-sha1" in keys(manifdep)
            push!(slugtuples,
                (proj, manifdep["uuid"], manifdep["git-tree-sha1"], :pkg)
            )
        else #assume stdlib 
            push!(slugtuples,
                (proj, manifdep["uuid"], "", :stdlib))
        end
    end
    return slugtuples
end

"""
    find where the package `name` with `uuid` and `sha1` is installed in
    the `depotpaths`
"""
function find_installed(name::String, uuid, sha1, depotpaths)
    #stolen from Pkg.jl/Operations
    uuid = Base.UUID(uuid)
    sha1 = Base.SHA1(hex2bytes(sha1))
    slug_default = Base.version_slug(uuid, sha1)
    # 4 used to be the default so look there first
    for slug in (slug_default, Base.version_slug(uuid, sha1, 4))
        for depot in depotpaths
            path = abspath(depot, "packages", name, slug)
            ispath(path) && return path
        end
    end
    ## keep the following because Pkg.jl does this.
    ## doesnt the loop above already do abspath(depot[1],...,slug_default)?
    ## why is this needed ?. 
    return abspath(depots1(depotpaths), "packages", name, slug_default)
end

"""
    get comma separated paths of folders that the deps inside Project.toml are resolved to,
    filename: the file inside some project
    depotpath: julia depot path
    juliaversion: juliaversion (for stdlibs)
"""
function get_rg_paths(filename, depotpath)
    slugtuples = get_slugtuples(filename)
    ret = String[]
    for slugtuple in slugtuples
        if slugtuple[end] == :pkg
            push!(ret, find_installed(slugtuple[1:3]..., depotpath))
        elseif slugtuple[end] == :devpkg
            push!(ret, slugtuple[3])
        elseif slugtuple[end] == :stdlib
            push!(ret, stdlib_path(slugtuple[1]))
        end
    end
    return join(ret, " ")
end

function get_rg_paths(filename)
    depotpath = Base.DEPOT_PATH
    get_rg_paths(filename, depotpath)
end

function matchdep(deps, uuid)
    for dep in deps
        if dep["uuid"] == uuid
            return dep
        end
    end
end
print(get_rg_paths(ARGS...))
