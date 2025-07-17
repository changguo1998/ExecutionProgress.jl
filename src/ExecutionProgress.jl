module ExecutionProgress

import Base.Dict

export Step, ProjectPath, Dict

using TOML

const DEFAULT_FLAG_DIR_NAME = ".excution_progress"
const DEFAULT_COMMANDS_FILE_NAME = "excution_progress.toml"

function _randstr(len::Integer=8)
    return String(
        rand(['a':'z'; 'A':'Z'; '0':'9'], len)
    )
end

function _convert_to_linux_style_path(p::AbstractString)
    return replace(p, """\\""" => "/")
end

function apath(x, y...)
    return abspath(x, y...) |> _convert_to_linux_style_path
end

# =============== Type Definitions ===============
struct Step
    id::Int
    name::String
    preprocess::String
    command::String
    workdir::String

    function Step(
        id::Int,
        name::String,
        preprocess::String,
        command::String,
        workdir::String)

        _name = String(join(split(name; keepempty=false), '_'))
        _workdir = String(apath(workdir))
        return new(id, _name, preprocess, command, _workdir)
    end
end

function Step(
    id::Integer,
    name::AbstractString,
    preprocess::AbstractString,
    command::AbstractString,
    workdir::AbstractString)
    return Step(
        Int(id),
        String(name),
        String(preprocess),
        String(command),
        String(workdir)
        )
end

function Step(d::Base.Dict{String,Any})
    _d = Base.Dict{String,Any}(
        "id" => 0,
        "name" => _randstr(8),
        "preprocess" => "",
        "workdir" => "",
        "command" => ""
    )
    for (k, v) in d
        if k in keys(_d)
            _d[k] = v
        end
    end
    return Step(
        _d["id"],
        _d["name"],
        _d["preprocess"],
        _d["command"],
        _d["workdir"]
        )
end

function Dict(s::Step)
    return Base.Dict{String,Any}(
        "id" => s.id,
        "name" => s.name,
        "preprocess" => s.preprocess,
        "workdir" => s.workdir,
        "command" => s.command
    )
end

struct ProjectPath
    name::String
    mode::Symbol
    flag_dir::String
    commands_file::String

    function ProjectPath(
        name::String,
        mode::Symbol,
        flag_dir::String,
        commands_file::String)

        if isempty(name)
            (_, _name) = splitdir(pwd())
        else
            _name = name
        end
        _name = String(_name)

        if mode in (:script, :executor)
            _mode = mode
        else
            error("mode must be either :script or :executor")
        end

        if isempty(flag_dir)
            _flag_dir = String(apath(pwd(), DEFAULT_FLAG_DIR_NAME))
        else
            _flag_dir = String(apath(flag_dir))
        end

        if isempty(commands_file)
            _commands_file = String(apath(pwd(), DEFAULT_COMMANDS_FILE_NAME))
        else
            _commands_file = String(apath(commands_file))
        end

        return new(_name, _mode, _flag_dir, _commands_file)
    end
end

function ProjectPath(
    name::AbstractString,
    mode::Union{Symbol,AbstractString},
    flag_dir::AbstractString,
    commands_file::AbstractString)

    return ProjectPath(
        String(name),
        Symbol(mode),
        String(flag_dir),
        String(commands_file)
        )
end

function ProjectPath(;
    name::AbstractString="",
    mode::Union{Symbol,AbstractString}=:script,
    flag_dir::AbstractString="",
    commands_file::AbstractString="")
    return ProjectPath(name, mode, flag_dir, commands_file)
end

function ProjectPath(d::Base.Dict{String,Any})
    _d = Base.Dict{String,Any}(
        "name" => "",
        "mode" => "script",
        "flag_dir" => "",
        "commands_file" => ""
    )
    for (k, v) in d
        if k in keys(_d)
            _d[k] = v
        end
    end
    return ProjectPath(
        _d["name"],
        _d["mode"],
        _d["flag_dir"],
        _d["commands_file"]
        )
end

function Dict(p::ProjectPath)
    return Base.Dict{String,Any}(
        "name" => p.name,
        "mode"  => String(p.mode),
        "flag_dir" =>  p.flag_dir ,
        "commands_file"  =>  p.commands_file
    )
end

# =============== IO ===============

export load_commands_file

"""
```
load_commands_file(path) -> (ProjectPath, Step[...])
```
load commands from TOML file
"""
function load_commands_file(p::AbstractString=abspath(pwd(), DEFAULT_COMMANDS_FILE_NAME))
    if isfile(p)
        t = TOML.parsefile(p)
    else
        error("File: $p not exist.")
    end
    return (ProjectPath(t["project"]), Step.(t["steps"]))
end

export print_commands_file

"""
```
print_commands_file(prj, steps, filepath)
```

write commands and project parameters into a TOML file
"""
function print_commands_file(
    prj::ProjectPath=ProjectPath(),
    steps::Vector{Step} = Step[],
    path::AbstractString=abspath(pwd(), DEFAULT_COMMANDS_FILE_NAME)
    )

    d = Dict{String,Any}(
        "project" => Dict(prj),
        "steps" => Dict.(steps)
    )

    open(path, "w") do io
        TOML.print(io, d)
    end

    return nothing
end

# =============== Script mode ===============
export print_caller_script

"""
```
print_caller_script(filepath, ProjectPath, Step)
```
write a call script of 1 step
"""
function print_caller_script(f::AbstractString, p::ProjectPath, s::Step)
    flagdir = p.flag_dir
    step_tag = join([s.id, s.name], "_")
    open(f, "w") do io
        println(io, "#!/usr/bin/env bash")
        println(io, "touch ", apath(flagdir, step_tag * ".begin"), " && \\")
        println(io, "cd ", apath(s.workdir), " && \\")
        if !isempty(s.preprocess)
            println(io, s.preprocess,  " && \\")
        end
        println(io, s.command,  " && \\")
        println(io, "touch ", apath(flagdir, step_tag * ".end"))
    end
    return nothing
end

export print_caller_script_list

"""
```
print_caller_script_list(dir, ProjectPath, steps)
```

write caller scripts for each step into directory
"""
function print_caller_script_list(d::AbstractString, p::ProjectPath, ss::Vector{Step})
    if !isdir(d)
        mkpath(d)
    end
    idxs = sortperm(ss, by=s->s.id)
    open(joinpath(d, "0_run_all.sh"), "w") do io
        println(io, "#/bin/bash\nset -x\n")
        println(io, "mkdir -p ", p.flag_dir)
        for i = idxs
            _s = ss[i]
            _callername = join([_s.id, _s.name], "_")*".sh"
            println(io, "bash ", _callername)
        end
    end
    for s in ss
        step_tag = join([s.id, s.name], "_")
        step_file_script_name = joinpath(d, step_tag * ".sh")
        print_caller_script(step_file_script_name, p, s)
    end
    return nothing
end

end # module ExecutionProgress
