export PotcarGenerator, PotcarValidator

struct PotcarGenerator{T,S}
    potentials_dir::T
    pot_database::Dict{S,T}
end

function locate_potcars(gen::PotcarGenerator{T,S}, elements) where {T,S}
    potentials = LittleDict{S,T}()
    for element in elements
        potential_name = get(gen.pot_database, element, element)
        file = joinpath(gen.potentials_dir, potential_name, "POTCAR")
        potentials[element] = file
        if !isfile(file)
            error("POTCAR for $element (potential $potential_name) not found in $file")
        end
    end
    return potentials
end

function concat_potcars(gen::PotcarGenerator, elements)
    potcar_map = locate_potcars(gen, elements)
    return join(read(potcar_map[element], String) for element in elements)
end

function (gen::PotcarGenerator)(cell::Cell)
    elements = ElementExtractor()(cell)  # Implement separately
    return concat_potcars(gen, elements)
end
function (gen::PotcarGenerator)(file, cell::Cell)
    content = gen(cell)
    open(file, "w") do io
        write(io, content)
    end
end

struct PotcarValidator end

function (gen::PotcarValidator)(potcar_file, poscar_file)
    mod = lazy_pyimport("pymatgen.io.vasp")
    poscar = PoscarParser()(poscar_file)
    symbols_from_poscar = ElementExtractor()(poscar)
    potcar = mod.Potcar.from_file(potcar_file)
    symbols_from_potcar = pyconvert(Vector{String}, potcar.symbols)
    return symbols_from_poscar == symbols_from_potcar
end
