@info "Installing FOOOF"
using PyCall
pip = pyimport("pip")
flags = split(get(ENV, "PIPFLAGS", ""))
ver = get(ENV, "FOOOFVERSION", "")
packages = ["""fooof$(isempty(ver) ? "" : "==")$(ver)"""]

@info "Package requirements:" packages
@info "Flags for pip install:" flags
ver = isempty(ver) ? "latest" : ver
@info "FOOOF version:" ver
pip.main(["install"; flags; packages])
