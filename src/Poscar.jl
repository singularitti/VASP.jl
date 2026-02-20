using CrystallographyBase: Cell, Lattice

export CifParser, PoscarParser, ElementExtractor, ElementCounter, LatticeExtractor

struct CifParser <: Parser end
struct PoscarParser <: Parser end
struct ElementExtractor <: Processor end
struct ElementCounter <: Processor end
struct LatticeExtractor <: Processor end

function (::CifParser)(file)
    mod = lazy_pyimport("pymatgen.io.cif")
    parser = mod.CifParser(file)
    return only(parser.parse_structures())
end
function (::PoscarParser)(file)
    mod = lazy_pyimport("pymatgen.io.vasp")
    poscar = mod.Poscar.from_str(read(file, String))
    cell = pyconvert(Cell, poscar.structure)
    return cell
end
function (::ElementExtractor)(file)
    cell = PoscarParser()(file)
    return unique(cell.atoms)
end
function (::ElementCounter)(file)
    cell = PoscarParser()(file)
    return counter(cell.atoms)
end
function (::LatticeExtractor)(file)
    cell = PoscarParser()(file)
    return cell.lattice
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

function counter(iter)
    d = LittleDict{eltype(iter),Int}()
    for x in iter
        d[x] = get(d, x, 0) + 1
    end
    return d
end
