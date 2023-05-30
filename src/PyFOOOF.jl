module PyFOOOF

#####
##### Dependencies
#####

using Reexport

@reexport using PythonCall

######
###### Actual functionality
######

const fooof = PythonCall.pynew()

function __init__()
    # all of this is __init__() so that it plays nice with precompilation
    # see https://github.com/cjdoris/PythonCall.jl/blob/5ea63f13c291ed97a8bacad06400acb053829dd4/src/Py.jl#L85-L96
    PythonCall.pycopy!(fooof, pyimport("fooof"))
    # don't eval into the module while precompiling; this breaks precompilation
    # of downstream modules (see #4)
    if ccall(:jl_generating_output, Cint, ()) == 0
        # delegate everything else to fooof
        for pn in propertynames(fooof)
            isdefined(@__MODULE__, pn) && continue
            prop = getproperty(fooof, pn)
            @eval $pn = $prop
        end
    end
    return nothing
end

end #module
