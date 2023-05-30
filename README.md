# PyFOOOF.jl
Julia interface to [FOOOF](https://github.com/fooof-tools/fooof)

[![Build Status][build-img]][build-url] [![CodeCov][codecov-img]][codecov-url]

[build-img]: https://github.com/beacon-biosignals/PyFOOOF.jl/workflows/CI/badge.svg
[build-url]: https://github.com/beacon-biosignals/PyFOOOF.jl/actions
[codecov-img]: https://codecov.io/github/beacon-biosignals/PyFOOOF.jl/badge.svg?branch=main
[codecov-url]: https://codecov.io/github/beacon-biosignals/PyFOOOF.jl?branch=main


## Installation
This package uses [`PythonCall`](https://cjdoris.github.io/PythonCall.jl) to make
[FOOOF](https://fooof-tools.github.io/fooof/index.html) available from within Julia.
Additional control over Python and FOOOF versions can be exercised by using
[`CondaPkg`](https://github.com/cjdoris/CondaPkg.jl) to control the local versions.

Note that FOOOF uses [`matplotlib`](https://matplotlib.org/) for plotting, but does not install it automatically as a dependency.
The Julia package [`PythonPlot`](https://github.com/JuliaPy/PythonPlot.jl), which provides a Julia interface to `matplotlib`, is useful for installing `matplotlib` and manipulating the rendered plots.

## Usage

In the same philosophy as PythonCall, this allows for the transparent use of
FOOOF from within Julia.
The major things the package does are wrap the installation of FOOOF, load all
the FOOOF functionality into the module namespace, and provide a few accessors.

### Exposing FOOOF in Julia

For example, in Python you can create a new FOOOF model like this:

```python
>>> import fooof

>>> fm = fooof.FOOOF()
```

With PyFOOOF, you can do this from within Julia.

```julia
julia> using PyFOOOF

julia> fm = PyFOOOF.FOOOF();
```

The PythonCall infrastructure also means that Python docstrings are available
in Julia:

<details><summary>Example</summary>

```julia
help?> PyFOOOF.FOOOF
  Python class FOOOF.

  Model a physiological power spectrum as a combination of aperiodic and periodic components.

  WARNING: FOOOF expects frequency and power values in linear space.

  Passing in logged frequencies and/or power spectra is not detected,
  and will silently produce incorrect results.

  Parameters
  ----------
  peak_width_limits : tuple of (float, float), optional, default: (0.5, 12.0)
      Limits on possible peak width, in Hz, as (lower_bound, upper_bound).
  max_n_peaks : int, optional, default: inf
      Maximum number of peaks to fit.
  min_peak_height : float, optional, default: 0
      Absolute threshold for detecting peaks, in units of the input data.
  peak_threshold : float, optional, default: 2.0
      Relative threshold for detecting peaks, in units of standard deviation of the input data.
  aperiodic_mode : {'fixed', 'knee'}
      Which approach to take for fitting the aperiodic component.
  verbose : bool, optional, default: True
      Verbosity mode. If True, prints out warnings and general status updates.

  Attributes
  ----------
  freqs : 1d array
      Frequency values for the power spectrum.
  power_spectrum : 1d array
      Power values, stored internally in log10 scale.
  freq_range : list of [float, float]
      Frequency range of the power spectrum, as [lowest_freq, highest_freq].
  freq_res : float
      Frequency resolution of the power spectrum.
  fooofed_spectrum_ : 1d array
      The full model fit of the power spectrum, in log10 scale.
  aperiodic_params_ : 1d array
      Parameters that define the aperiodic fit. As [Offset, (Knee), Exponent].
      The knee parameter is only included if aperiodic component is fit with a knee.
  peak_params_ : 2d array
      Fitted parameter values for the peaks. Each row is a peak, as [CF, PW, BW].
  gaussian_params_ : 2d array
      Parameters that define the gaussian fit(s).
      Each row is a gaussian, as [mean, height, standard deviation].
  r_squared_ : float
      R-squared of the fit between the input power spectrum and the full model fit.
  error_ : float
      Error of the full model fit.
  n_peaks_ : int
      The number of peaks fit in the model.
  has_data : bool
      Whether data is loaded to the object.
  has_model : bool
      Whether model results are available in the object.

  Notes
  -----
  - Commonly used abbreviations used in this module include:
    CF: center frequency, PW: power, BW: Bandwidth, AP: aperiodic
  - Input power spectra must be provided in linear scale.
    Internally they are stored in log10 scale, as this is what the model operates upon.
  - Input power spectra should be smooth, as overly noisy power spectra may lead to bad fits.
    For example, raw FFT inputs are not appropriate. Where possible and appropriate, use
    longer time segments for power spectrum calculation to get smoother power spectra,
    as this will give better model fits.
  - The gaussian params are those that define the gaussian of the fit, where as the peak
    params are a modified version, in which the CF of the peak is the mean of the gaussian,
    the PW of the peak is the height of the gaussian over and above the aperiodic component,
    and the BW of the peak, is 2*std of the gaussian (as 'two sided' bandwidth).
```

</details>

### Helping with type conversions

FOOOF can be quite sensitive to the distinction between Python lists and NumPy
arrays, which can be problematic when relying on fully automatic conversions,
especially of nested lists.
For example, the [FOOOF tutorial "Tuning and Troubleshooting"](https://fooof-tools.github.io/fooof/auto_tutorials/plot_07-TroubleShooting.html) includes this statement
```python
>>> gauss_params = [[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]]
```
When executed via PyCall, this results in a Julia `Vector{Vector{Float64}}`.

```julia
julia> Py([[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]])
Python:
Julia:
3-element Vector{Vector{Float64}}:
 [10.0, 1.0, 2.5]
 [20.0, 0.8, 2.0]
 [32.0, 0.6, 1.0]
```

This results in an error:

```julia
julia> gen_power_spectrum = fooof.sim.gen.gen_power_spectrum;

julia> f_range = [1, 50];

julia> ap_params = [20, 2];

julia> nlv = 0.1;

julia> gauss_params = [[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]];

julia> freqs, spectrum = gen_power_spectrum(f_range, ap_params, gauss_params, nlv)
ERROR: Python: ValueError: operands could not be broadcast together with shapes (99,) (3,)
Python stacktrace:
 [1] gaussian_function
   @ fooof.core.funcs ~/PyFOOOF.jl/.CondaPkg/env/lib/python3.11/site-packages/fooof/core/funcs.py:39
 [2] gen_periodic
   @ fooof.sim.gen ~/PyFOOOF.jl/.CondaPkg/env/lib/python3.11/site-packages/fooof/sim/gen.py:342
 [3] gen_power_vals
   @ fooof.sim.gen ~/PyFOOOF.jl/.CondaPkg/env/lib/python3.11/site-packages/fooof/sim/gen.py:401
 [4] gen_power_spectrum
   @ fooof.sim.gen ~/PyFOOOF.jl/.CondaPkg/env/lib/python3.11/site-packages/fooof/sim/gen.py:147
Stacktrace:
...
```

The workaround is to force `gauss_params` to be interpreted as as a list of lists, which also preserves
the individual elements' types (int vs float):

```julia
julia> gauss_params = pylist.([[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]])
3-element Vector{Py}:
 [10.0, 1.0, 2.5]
 [20.0, 0.8, 2.0]
 [32.0, 0.6, 1.0]

julia> freqs, spectrum = gen_power_spectrum(f_range, ap_params, gauss_params, nlv)
Python:
(array([ 1. ,  1.5,  2. ,  2.5,  3. ,  3.5,  4. ,  4.5,  5. ,  5.5,  6. ,
        6.5,  7. ,  7.5,  8. ,  8.5,  9. ,  9.5, 10. , 10.5, 11. , 11.5,
       12. , 12.5, 13. , 13.5, 14. , 14.5, 15. , 15.5, 16. , 16.5, 17. ,
       17.5, 18. , 18.5, 19. , 19.5, 20. , 20.5, 21. , 21.5, 22. , 22.5,
       23. , 23.5, 24. , 24.5, 25. , 25.5, 26. , 26.5, 27. , 27.5, 28. ,
       28.5, 29. , 29.5, 30. , 30.5, 31. , 31.5, 32. , 32.5, 33. , 33.5,
       34. , 34.5, 35. , 35.5, 36. , 36.5, 37. , 37.5, 38. , 38.5, 39. ,
       39.5, 40. , 40.5, 41. , 41.5, 42. , 42.5, 43. , 43.5, 44. , 44.5,
                             ... 17 more lines ...
       1.08500258e+17, 8.96225267e+16, 7.27460728e+16, 8.01572652e+16,
       5.28615329e+16, 5.02376587e+16, 7.65356201e+16, 1.27226878e+17,
       1.04460011e+17, 1.14497405e+17, 7.12727925e+16, 5.40055512e+16,
       7.60772143e+16, 4.41011048e+16, 2.93448991e+16, 6.10439802e+16,
       6.86158349e+16, 6.21644140e+16, 7.38110102e+16, 6.02312564e+16,
       5.34817797e+16, 3.78961836e+16, 4.58707098e+16, 3.52330831e+16,
       4.15835216e+16, 6.86889336e+16, 4.55552304e+16, 4.63646306e+16,
       3.54988480e+16, 7.43140499e+16, 2.53356592e+16]))
```

If other automatic type conversions are found to be problematic or there are
particular FOOOF functions that don't play nice via the default PythonCall mechanisms,
then issues and pull requests are welcome.

Many of these problematic conversions can be fixed with relatively straightforward (
and backward compatible) changes to FOOOF. In other words, upstream PRs are
also welcome.
