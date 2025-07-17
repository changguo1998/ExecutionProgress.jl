module ExecutionProgress

using TOML

const DEFAULT_FLAG_DIR_NAME = ".excution_progress"
const DEFAULT_COMMANDS_FILENAME = "excution_progress.toml"

struct Step
    id::Int
    name::String
    preprocess_file::String
    command::String
    work_dir::String
end

struct ProjectPath
    flag_dir::String
    commands_file::String
end

end # module ExecutionProgress
