module PyFOOOF

using PyCall

#####
##### Exports
#####

#####
##### _init_
#####

const fooof = PyNULL()

function load_python_deps!()
    copy!(fooof, pyimport("fooof"))
    return nothing
end

function __init__()
    # all of this is __init__() so that it plays nice with precompilation
    # see https://github.com/JuliaPy/PyCall.jl/#using-pycall-from-julia-modules
    copy!(fooof, pyimport("fooof"))
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
