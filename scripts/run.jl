using Distributed

# ---- Load packages on all workers ----
@everywhere begin
    using FileTrees
    using PythonCall
    using VASP
end

const ROOT = "/path/to/root"

# ---- Build file tree ----
workdirs = walk_workdirs(ROOT)

files = list_files(workdirs, "OUTCAR")

# ---- Create lazy task graph ----
lazy_results = FileTrees.load(files; lazy=true) do file
    index(path(file), EnergyParser())
end

# ---- Execute tasks ----
results = exec(lazy_results)

# ---- Extract values ----
vals = values(results)
