using PythonCall: pyconvert_add_rule

function __init__()
    # This string must match the Python module and class name exactly
    pyconvert_add_rule("pymatgen.core.structure:Structure", Cell, _structure2cell)
    pyconvert_add_rule("builtins:tuple", DataFrame, _pydicts2dataframe)
    return nothing
end
