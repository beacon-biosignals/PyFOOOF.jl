# FOOOF.jl
Julia interface to [FOOOF](https://github.com/fooof-tools/fooof)

Right now, you can build a FOOOF model and extract periodic / aperiodic parameters from a Periodogram or Samples object.

```
using FOOOF

fooof_obj = average_fooof_parameters_in_band(p::Periodogram, band::Tuple{Float64, Float64})
fooof_obj = average_fooof_parameters(p::Samples, band::Tuple)

