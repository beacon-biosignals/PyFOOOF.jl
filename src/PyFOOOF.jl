module PyFOOOF

using PyCall

#####
##### Exports
#####

#####
##### init
#####

const fooof = PyNULL()

function __init__()
    # all of this is __init__() so that it plays nice with precompilation
    # see https://github.com/JuliaPy/PyCall.jl/#using-pycall-from-julia-modules
    copy!(fooof, pyimport("fooof"))
    # don't eval into the module while precompiling; this breaks precompilation
    # of downstream modules
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

"""
    install_matplotlib(ver="")
Install matplotlib using the specified version.
The default version is the latest stable version.
"""
function install_matplotlib(version="latest"; verbose=false)
    verbose && @info "Installing matplotlib"
    pip = pyimport("pip")
    flags = split(get(ENV, "PIPFLAGS", ""))
    packages = ["matplotlib" * (version == "latest" ? "" : "==$version")]
    if verbose
        @info "Package requirements:" packages
        @info "Flags for pip install:" flags
        @info "matplotlib version:" version
    end
    pip.main(["install"; flags; packages])
    return nothing
end


end #module
