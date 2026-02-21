# module Indexing

using PythonCall: pyconvert

export EnergyParser

abstract type Indexer end

struct EnergyParser <: Indexer end
abstract type Parser <: Indexer end
abstract type Processor <: Indexer end

function (::EnergyParser)(file)
    mod = lazy_pyimport("pymatgen.io.vasp")
    outcar = mod.Outcar(file)
    return pyconvert(Float64, outcar.final_fr_energy)
end

# end
