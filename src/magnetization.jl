using Crystallography: MagneticAtom, natoms
using DataFrames: ByRow, DataFrame, Not, eachrow, select, nrow, groupby

export MagnetizationParser, groupby_file, magnetic_cell

struct MagnetizationParser <: Indexer end
function (::MagnetizationParser)(file)
    mod = lazy_pyimport("pymatgen.io.vasp")
    outcar = mod.Outcar(file)
    df = pyconvert(DataFrame, outcar.magnetization)
    return select(df, Not(:tot))
end
function (parser::MagnetizationParser)(workdir::WorkDir)
    poscar_file = joinpath(workdir.path, "POSCAR")
    outcar_file = joinpath(workdir.path, "OUTCAR")
    cell = PoscarParser()(poscar_file)
    dataframe = parser(outcar_file)
    magmoms = ByRow(sum)(eachrow(dataframe))
    return magnetic_cell(cell, magmoms)
end

function magnetic_cell(cell::Cell, magmoms::AbstractArray)
    if length(magmoms) != natoms(cell)
        throw(DimensionMismatch("number of magmoms must match number of atoms in cell!"))
    end
    return Cell(Lattice(cell), cell.positions, MagneticAtom.(cell.atoms, magmoms))
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

function _pydicts2dataframe(::Type{DataFrame}, dicts::Py)
    # Verify elements are dict-like before attempting conversion, so we can cleanly reject.
    for item in dicts
        if !pyisinstance(item, pybuiltins.dict)
            return pyconvert_unconverted()
        end
    end
    # Convert: list/tuple of dicts -> Vector{Dict} -> DataFrame
    df = DataFrame(map(Base.Fix1(pyconvert, Dict), dicts))
    return pyconvert_return(convert(DataFrame, df))
end
