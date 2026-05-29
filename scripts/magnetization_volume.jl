using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using VASP
using Crystallography: cellvolume
using DataFrames: DataFrame

function parse_magnetization_volume(workdir::WorkDir)
    contcar_file = joinpath(workdir.path, "CONTCAR")
    if !isfile(contcar_file) || stat(contcar_file).size == 0
        throw(ArgumentError("Missing or empty CONTCAR in $(workdir.path)"))
    end

    cell = VASP.PoscarParser()(contcar_file)
    volume = cellvolume(cell)
    if volume <= 0
        throw(ArgumentError("CONTCAR cell volume must be positive in $(workdir.path)"))
    end

    outcar_file = joinpath(workdir.path, "OUTCAR")
    dataframe = VASP.MagnetizationParser()(outcar_file)
    for col in (:d, :p, :s)
        dataframe[!, col] ./= volume
    end
    return dataframe
end

function summarize_magnetization_volume(workdir::WorkDir)
    contcar_file = joinpath(workdir.path, "CONTCAR")
    if !isfile(contcar_file) || stat(contcar_file).size == 0
        throw(ArgumentError("Missing or empty CONTCAR in $(workdir.path)"))
    end

    cell = VASP.PoscarParser()(contcar_file)
    volume = cellvolume(cell)
    if volume <= 0
        throw(ArgumentError("CONTCAR cell volume must be positive in $(workdir.path)"))
    end

    outcar_file = joinpath(workdir.path, "OUTCAR")
    dataframe = VASP.MagnetizationParser()(outcar_file)
    total_d = sum(dataframe.d)
    total_p = sum(dataframe.p)
    total_s = sum(dataframe.s)

    return DataFrame(;
        ID=basename(workdir.path),
        volume=volume,
        atom_count=nrow(dataframe),
        d=total_d,
        p=total_p,
        s=total_s,
        d_vol=total_d / volume,
        p_vol=total_p / volume,
        s_vol=total_s / volume,
    )
end

function write_csv(df::DataFrame, file::String)
    open(file, "w") do io
        println(io, join(names(df), ","))
        for row in eachrow(df)
            println(io, join(string.(collect(row)), ","))
        end
    end
end

function main()
    if length(ARGS) < 2
        error(
            "Usage: julia --project=. scripts/magnetization_volume.jl <root> <output_dir>"
        )
    end

    root = ARGS[1]
    outdir = ARGS[2]
    mkpath(outdir)

    workdirs = VASP.list_workdirs(root)
    summary = [summarize_magnetization_volume(wd) for wd in workdirs]
    output_file = joinpath(outdir, "magnetization_volume_summary.csv")
    write_csv(vcat(summary...), output_file)
    return println("Wrote summary CSV to ", output_file)
end

main()
