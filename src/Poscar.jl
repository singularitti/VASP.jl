using CrystallographyBase: Cell, Lattice
using PythonCall: Py, pyconvert_unconverted, pyconvert_return

export CifParser, PoscarParser

struct CifParser <: Indexer end
struct PoscarParser <: Indexer end

function (::CifParser)(file)
    mod = lazy_pyimport("pymatgen.io.cif")
    parser = mod.CifParser(file)
    return only(parser.parse_structures())
end
function (::PoscarParser)(file)
    mod = lazy_pyimport("pymatgen.io.vasp")
    poscar = mod.Poscar.from_str(read(file, String))
    return poscar.structure
end

function _structure2cell(::Type{<:Cell}, structure::Py)
    is_ordered = pyconvert(Bool, structure.is_ordered)
    if !is_ordered  # Reject disordered structures since Cell expects whole atoms
        return pyconvert_unconverted()
    end
    matrix = pyconvert(Matrix{Float64}, structure.lattice.matrix)
    lattice = Lattice(transpose(matrix)) # Uses the AbstractMatrix constructor
    positions = Vector{Vector{Float64}}()
    atoms = Vector{String}()
    for site in structure
        push!(positions, pyconvert(Vector{Float64}, site.frac_coords))
        push!(atoms, pyconvert(String, site.species_string))
    end
    return pyconvert_return(Cell(lattice, positions, atoms))
end
