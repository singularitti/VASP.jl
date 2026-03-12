export stopcar

"""
    stopcar(dir::WorkDir, abort=false)

Create a `STOPCAR` file in a valid VASP working directory. The argument must be a `WorkDir`
object. The output file will always be named `STOPCAR` and placed directly inside
`dir.path`.

By default the file contains
```text
LSTOP = .TRUE.
```
causing VASP to stop at the next ionic step. When `abort=true` the file
instead contains
```text
LABORT = .TRUE.
```
and VASP will halt at the next electronic iteration.

Returns the absolute path to the created file. An `ArgumentError` is
thrown if the provided path is not a valid `WorkDir`.
"""
function stopcar(dir::WorkDir, abort::Bool=false)
    if !isvalid(dir)
        throw(ArgumentError("`$(dir.path)` is not a valid VASP WorkDir"))
    end
    file = joinpath(dir.path, "STOPCAR")
    content = abort ? "LABORT = .TRUE.\n" : "LSTOP = .TRUE.\n"
    mkpath(dir.path)  # Ensure the directory exists even if validation passed
    open(file, "w") do io
        write(io, content)
    end
    return abspath(file)
end
