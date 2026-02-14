using Glob: @fn_str

export WorkDir, isinput, isoutput, isvalid, input_files, output_files, other_files

const VASP_INPUT_FILES = (
    "CHGCAR",
    "DYNMATFULL",
    "GAMMA",
    "ICONST",
    "INCAR",
    "KPOINTS",
    "KPOINTS_OPT",
    "KPOINTS_WAN",
    "ML_AB",
    "ML_FF",
    "PENALTYPOT",
    "POSCAR",
    "POTCAR",
    "QPOINTS",
    "Vasp.lock",
    "Vaspin.h5",
    "WANPROJ",
    "WAVECAR",
    "WAVEDER",
    "STOPCAR",
)
const VASP_OUTPUT_FILES = (
    "BSEFATBAND",
    "CHG",
    "CHGCAR",
    "CONTCAR",
    "CONTCAR_ELPH",
    "DOSCAR",
    "DYNMATFULL",
    "EIGENVAL",
    "ELFCAR",
    "IBZKPT",
    "LOCPOT",
    "ML_ABN",
    "ML_EATOM",
    "ML_FFN",
    "ML_HEAT",
    "ML_HIS",
    "ML_LOGFILE",
    "ML_REG",
    "NMRCURBX",
    "OSZICAR",
    "OUTCAR",
    "Output",
    "PCDAT",
    "PARCHG",
    "Phelel_params.hdf5",
    "POT",
    "PRJCAR",
    "PROCAR",
    "PROCAR_OPT",
    "PROOUT",
    "REPORT",
    "TMPCAR",
    "UIJKL",
    "URijkl",
    "Vaspelph.h5",
    "Vaspout.h5",
    "Vaspwave.h5",
    "vasprun.xml",
    "VIJKL",
    "VRijkl",
    "WANPROJ",
    "WAVECAR",
    "WAVEDER",
    "XDATCAR",
)
const WFULL_TMP = fn"WFULL????.tmp"  # 4 chars after WFULL
const W_TMP = fn"W????.tmp"  # 4 chars after W

struct WorkDir{T}
    path::T
end

function isinput(path)
    name = basename(path)
    return (name in VASP_INPUT_FILES) || occursin(WFULL_TMP, name) || occursin(W_TMP, name)
end

function isoutput(path)
    name = basename(path)
    return (name in VASP_OUTPUT_FILES) || occursin(WFULL_TMP, name) || occursin(W_TMP, name)
end

isvalid(path) = isinput(path) || isoutput(path)
isvalid(dir::WorkDir) = any(isvalid, readdir(dir.path))

input_files(dir::WorkDir) = filter(isinput, readdir(dir.path))

output_files(dir::WorkDir) = filter(isoutput, readdir(dir.path))

other_files(dir::WorkDir) = filter(!isvalid, readdir(dir.path))
