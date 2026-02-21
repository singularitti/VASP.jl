using PythonCall:
    Py,
    pyimport,
    pyconvert,
    pyisinstance,
    pybuiltins,
    pyconvert_unconverted,
    pyconvert_return

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
