@info "Installing FOOOF"
using PyCall
pip = pyimport("pip")
flags = split(get(ENV, "PIPFLAGS", ""))
ver = get(ENV, "FOOOFVERSION", "1")
packages = ["""fooof$(isempty(ver) ? "" : "==")$(ver)"""]

@info "Package requirements:" packages
@info "Flags for pip install:" flags
ver = isempty(ver) ? "latest" : ver
@info "FOOOF version:" ver
pip.main(["install"; flags; packages])
