using PythonCall: pyimport

export EnergyParser, index

const PYMATGEN_IO_VASP = pyimport("pymatgen.io.vasp")

abstract type Indexer end

struct EnergyParser <: Indexer end

function index(file, ::EnergyParser)
    outcar = PYMATGEN_IO_VASP.Outcar(file)
    return outcar.final_fr_energy
end
