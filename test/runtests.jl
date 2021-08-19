using PyCall
using PyFOOOF
using Test

# test that this works
fooof = PyFOOOF.fooof

# this example is adapted from the FOOOF tutorial
# https://fooof-tools.github.io/fooof/auto_tutorials/plot_07-TroubleShooting.html

FOOOF = fooof.FOOOF
# test that this works
FOOOFGroup = PyFOOOF.FOOOFGroup

param_sampler = fooof.sim.params.param_sampler
gen_power_spectrum = fooof.sim.gen.gen_power_spectrum
gen_group_power_spectra = fooof.sim.gen.gen_group_power_spectra
# XXX this fails for fooof.sim.utils.set_random_seed
# it seems to be a pseudo-bug in upstream: the python module's init
# doesn't import ("include") everything from that dir, but CPython
# seems to be able to cope:
# https://github.com/fooof-tools/fooof/blob/f7b4ed8d074a3eaa03707c2c3c09413e6ff74192/fooof/sim/__init__.py#L6
set_random_seed =  pyimport("fooof.sim.utils").set_random_seed

f_range = [1, 50]
ap_params = [20, 2]
# XXX PyCall's aggressive to NumPy arrays creates problems here
# so we force it be treated as raw Python code (py-prefix)
# and NOT be converted to a native Julia array (o-suffix)
gauss_params = py"[[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]]"
nlv = 0.1
set_random_seed(21)

freqs, spectrum = gen_power_spectrum(f_range, ap_params, gauss_params, nlv)

fm = FOOOF(; peak_width_limits=py"[1, 8]"o, max_n_peaks=6, min_peak_height=0.4)
fm.fit(freqs, spectrum)

ground_truth = float.(py"$(gauss_params)")
actual_estimates = fm.gaussian_params_
expected_estimates = [9.82  0.91  2.43; 20.03  0.82  1.94; 31.85  0.57  1.11]
@test actual_estimates ≈ expected_estimates atol=0.01
