using Logging: @info, @warn, @error
using Mustache: Mustache
using OrderedCollections: OrderedSet

export TemplateDistributor, TemplateModifier, render, modify, render_modify, patch

"""
    TemplateDistributor

Distribute template input files to VASP working directories.
"""
struct TemplateDistributor{T}
    src_files::Vector{T}
end

function TemplateDistributor(src_files)
    T = eltype(src_files)
    resolved_files = T[]
    for src_file in src_files
        path = abspath(src_file)
        if isfile(path)
            push!(resolved_files, path)
        else
            @warn "Source file '$src_file' does not exist and will be skipped."
        end
    end
    return TemplateDistributor{T}(resolved_files)
end

"""
    (distributor::TemplateDistributor)(start_dir; overwrite=false)

Copy source files to all VASP working directories found under `start_dir`.
"""
function (distributor::TemplateDistributor)(start_dir; overwrite=false)
    finder = WorkdirFinder()
    workdirs = find(finder, start_dir)
    successful_dirs = OrderedSet{typeof(first(workdirs))}()
    if isempty(workdirs)
        return successful_dirs
    end
    for workdir in workdirs
        copied_files = false
        for src_file in distributor.src_files
            dest_file = joinpath(workdir, basename(src_file))
            try
                if isfile(dest_file) && !overwrite
                    @info "Skipping '$dest_file' as it already exists (overwrite=false)."
                    continue
                end
                cp(src_file, dest_file; force=true)
                @info "Copied '$src_file' to '$dest_file'."
                copied_files = true
            catch e
                @error "Failed to copy '$src_file' to '$dest_file': $e"
            end
        end
        if copied_files
            push!(successful_dirs, workdir)
        end
    end
    return successful_dirs
end

"""
    TemplateModifier

Represent a template file, supporting Mustache rendering and modification of target files in append or overwrite modes.
"""
@kwdef mutable struct TemplateModifier{S,T,D}
    template::S
    target_file::T
    target_dir::D
    append_mode::Bool = false
end

"""
    render(modifier::TemplateModifier, variables)

Render the template with provided variables and handle file content.
"""
function render(modifier::TemplateModifier, variables)
    target_path = joinpath(modifier.target_dir, modifier.target_file)
    rendered = Mustache.render(modifier.template, variables)
    if modifier.append_mode && isfile(target_path)
        existing = read(target_path, String)
        return existing * "\n" * rendered
    end
    return rendered
end

"""
    modify(modifier::TemplateModifier, final_content)

Write the final content to the target file in the given directory.
"""
function modify(modifier::TemplateModifier, final_content)
    target_path = joinpath(modifier.target_dir, modifier.target_file)
    if !modifier.append_mode && isfile(target_path)  # Overwrite mode
        try
            lines = readlines(target_path; keep=true)
            num_lines = length(lines)
            blank_content = "\n"^num_lines
            write(target_path, blank_content)
            @warn "Performed intermediate blanking on '$target_path'."
        catch e
            @error "Failed to blank '$target_path': $e"
            return false
        end
    end
    try
        write(target_path, final_content)
        if modifier.append_mode
            @info "Appended rendered template to '$target_path'."
        else
            @warn "Overwrote '$target_path' with rendered template"
        end
        return true
    catch e
        @error "Failed to modify '$target_path': $e"
        return false
    end
end

"""
    render_modify(modifier::TemplateModifier, variables)

Render the template with provided variables and modify the target file in the given directory.
"""
render_modify(modifier::TemplateModifier, variables) =
    modify(modifier, render(modifier, variables))

"""
    patch(modifier::TemplateModifier, patch_path=nothing)

Apply a unified diff patch to the target file in the given directory.
"""
function patch(modifier::TemplateModifier, patch_path=nothing)
    if Sys.which("patch") === nothing
        @error "`patch` command not found in PATH."
        return false
    end
    target_path = joinpath(modifier.target_dir, modifier.target_file)
    temp_patch = nothing
    if patch_path === nothing
        temp_patch_path, io = mktemp()
        write(io, modifier.template)
        close(io)
        patch_path = temp_patch_path
        temp_patch = temp_patch_path
    end
    cmd = `patch $target_path`
    try
        out = Pipe()
        err = Pipe()
        process = run(pipeline(cmd; stdin=patch_path, stdout=out, stderr=err); wait=false)
        wait(process)
        close(out.in)
        close(err.in)
        if success(process)
            @info "Applied patch to '$target_path': $(strip(read(out, String)))"
            return true
        else
            @error "Failed to apply patch to '$target_path': $(strip(read(err, String)))"
            return false
        end
    catch e
        @error "Failed to run patch command: $e"
        return false
    finally
        if temp_patch !== nothing
            try
                rm(temp_patch)
            catch
            end
        end
    end
end
