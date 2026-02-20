module VASP

using OrderedCollections: LittleDict

include("python.jl")
include("WorkDir.jl")
include("process.jl")
include("WorkStatus.jl")
include("Indexing.jl")
include("Poscar.jl")
include("Potcar.jl")
include("__init__.jl")

end
