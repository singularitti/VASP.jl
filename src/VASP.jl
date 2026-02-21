module VASP

using OrderedCollections: LittleDict

include("python.jl")
include("WorkDir.jl")
include("Indexing.jl")
include("process.jl")
include("WorkStatus.jl")
include("Poscar.jl")
include("Potcar.jl")
include("magnetization.jl")
include("__init__.jl")

end
