# module Indexing

using DataFrames: DataFrame, Not, select, nrow, groupby
using PythonCall: pyimport, pyconvert

export EnergyParser, MagnetizationFile, MagnetizationParser, index, groupby_file

const _PYMODULE_CACHE = Dict{String,Any}()  # Cache mapping module name -> PyObject
const _PYMODULE_CACHE_LOCK = ReentrantLock()  # Lock to make cache access thread-safe

# Thread-safe lazy importer for Python modules — avoids creating PyObjects at precompile time
function lazy_pyimport(modname::AbstractString)
    m = get(_PYMODULE_CACHE, modname, nothing)  # Fast path: return cached module if present
    if m === nothing  # Not cached yet
        lock(_PYMODULE_CACHE_LOCK)  # Acquire lock before mutating shared cache
        try
            m = get(_PYMODULE_CACHE, modname, nothing)  # Double-check cache after locking
            if m === nothing  # Still missing, do the import
                m = pyimport(modname)  # Perform Python import at runtime
                _PYMODULE_CACHE[modname] = m  # Store imported module in cache
            end
        finally
            unlock(_PYMODULE_CACHE_LOCK)  # Always release the lock
        end
    end
    return m
end

abstract type Indexer end

struct EnergyParser <: Indexer end

@enumx MagnetizationFile::UInt8 begin
    OUTCAR
    OSZICAR
end
struct MagnetizationParser{T} <: Indexer end

function index(file, ::EnergyParser)
    mod = lazy_pyimport("pymatgen.io.vasp")
    outcar = mod.Outcar(file)
    return pyconvert(Float64, outcar.final_fr_energy)
end
function index(file, ::MagnetizationParser{V}) where {V}
    mod = lazy_pyimport("pymatgen.io.vasp")
    outcar = mod.Outcar(file)
    if V == MagnetizationFile.OUTCAR
        df = DataFrame(map(Base.Fix1(pyconvert, Dict), outcar.magnetization))
        return select(df, Not(:tot))
    elseif V == MagnetizationFile.OSZICAR
        oszicar = mod.Oszicar(file)
        return DataFrame(oszicar.ionic_steps).mag
    else
        throw(ArgumentError("Unsupported magnetization file type: $V"))
    end
end

"""
    concat_with_file(dfs, files; cols=:setequal, copydfs=false)

Attach a `:file` column to each DataFrame using the corresponding entry in `files`,
concatenate all DataFrames, and return the combined DataFrame.

Arguments
- `dfs`: iterable of `DataFrame` objects.
- `files`: iterable of file identifiers (e.g., paths or names). Values are used *as-is*.
- `copydfs=false`: if `true`, copies each DataFrame before adding `:file` (preserves inputs).

Returns
- A single concatenated `DataFrame` with an added `:file` column.
"""
function concat_with_file(dfs, files, copydfs=false)
    out = DataFrame[]
    for (df, file) in zip(dfs, files)
        df2 = copydfs ? copy(df) : df
        df2.file = fill(file, nrow(df2))  # use `file` as-is
        push!(out, df2)
    end
    return vcat(out...)
end

"""
    groupby_file(dfs, files, copydfs=false)

Convenience wrapper: `groupby(concat_with_file(...), :file)`.
"""
function groupby_file(dfs, files, copydfs=false)
    return groupby(concat_with_file(dfs, files, copydfs), :file)
end

# end
