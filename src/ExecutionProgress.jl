module ExecutionProgress

using TOML

const DEFAULT_FLAG_DIR_NAME = ".excution_progress"
const DEFAULT_COMMANDS_FILENAME = "excution_progress.toml"

function _randstr(len::Integer=8)
    return String(
        rand(['a':'z'; 'A':'Z'; '0':'9'], len)
    )
end

struct Step
    id::Int
    name::String
    preprocess::String
    command::String
    workdir::String
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

function Step(d::Dict{String,Any})
    _d = Dict{String,Any}(
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
        d["id"],
        d["name"],
        d["preprocess"],
        d["command"],
        d["workdir"]
        )
end

struct ProjectPath
    name::String
    mode::Symbol
    flag_dir::String
    commands_file::String
end

function ProjectPath(
    name::AbstractString="",
    mode::Union{Symbol,AbstractString}=:script,
    flag_dir::AbstractString="",
    commands_file::AbstractString="")

    if isempty(name)
        (_, name) = splitdir(pwd())
    end

    _mode = Symbol(mode)
    if !(_mode in (:script, :executor))
        error("mode must be either :script or :executor")
    end

    if isempty(flag_dir)
        flag_dir = abspath(pwd(), DEFAULT_FLAG_DIR_NAME)
    end

    if isempty(commands_file)
        commands_file = abspath(pwd(), DEFAULT_COMMANDS_FILE_NAME)
    end

    return ProjectPath(
        String(name),
        _mode,
        String(flag_dir),
        String(commands_file)
        )
end

function ProjectPath(;
    name::AbstractString="",
    mode::Union{Symbol,AbstractString}=:script,
    flag_dir::AbstractString="",
    commands_file::AbstractString="")

    if isempty(name)
        (_, name) = splitdir(pwd())
    end

    _mode = Symbol(mode)
    if !(_mode in (:script, :executor))
        error("mode must be either :script or :executor")
    end

    if isempty(flag_dir)
        flag_dir = abspath(pwd(), DEFAULT_FLAG_DIR_NAME)
    end

    if isempty(commands_file)
        commands_file = abspath(pwd(), DEFAULT_COMMANDS_FILE_NAME)
    end

    return ProjectPath(
        String(name),
        _mode,
        String(flag_dir),
        String(commands_file)
        )
end

function ProjectPath(d::Dict{String,Any})
    _d = Dict{String,Any}(
        "name" => "",
        "mode" => ":script",
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

end # module ExecutionProgress
