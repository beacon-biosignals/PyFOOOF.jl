# PyFOOOF.jl
Julia interface to [FOOOF](https://github.com/fooof-tools/fooof)

[![Build Status][build-img]][build-url] [![CodeCov][codecov-img]][codecov-url]

[build-img]: https://github.com/beacon-biosignals/PyFOOOF.jl/workflows/CI/badge.svg
[build-url]: https://github.com/beacon-biosignals/PyFOOOF.jl/actions
[codecov-img]: https://codecov.io/github/beacon-biosignals/PyFOOOF.jl/badge.svg?branch=main
[codecov-url]: https://codecov.io/github/beacon-biosignals/PyFOOOF.jl?branch=main


## Installation
This package uses [`PyCall`](https://github.com/JuliaPy/PyCall.jl/) to make
[FOOOF](https://fooof-tools.github.io/fooof/index.html) available from within Julia.
Unsurprisingly, FOOOF and its dependencies need to be installed in order for this to work
and PyFOOOF will attempt to install when the package is built.

By default, this installation happens in the "global" path for the Python used
by PyCall. If you're using PyCall via its hidden Miniconda install, your own
Anaconda environment, or a Python virtual environment, this is what you want.
(The "global" path is sandboxed to the Conda/virtual environment.) If you are
however using system Python, then you should set `ENV["PIPFLAGS"] = "--user"`
before `add`ing / `build`ing the package. By default, PyFOOOF will use the latest
FOOOF 1.x release available on [PyPI](https://pypi.org/project/FOOOF/), but this can also
be changed via the `ENV["FOOOFVERSION"] = version_number` for your preferred
`version_number`.

Note that FOOOF-Python uses [`matplotlib`](https://matplotlib.org/) for plotting, but does not install it automatically as a dependency.
If you wish to take advantage of this functionality, the non-exported `install_matplotlib` function will install `matplotlib`, using the same environment variables as the main installation.
The Julia package [`PyPlot`](https://github.com/JuliaPy/PyPlot.jl), which provides a Julia interface to `matplotlib` is also useful for manipulating the rendered plots.

FOOOF-Python can also be installed them manually ahead of time.
From the shell, use `python -m pip install fooof` for the latest stable release
or `python -m pip install fooof==version_number` for a given `version_number`,
ensuring  that `python` is the same one that PyCall is using. Alternatively,
you can run this from within Julia:
```julia
using PyCall
pip = pyimport("pip")
pip.main(["install", "fooof==version_number"]) # specific version
```

If you do not specify a version via `==version`, then the latest versions will be
installed. If you wish to upgrade versions, you can use
`python -m pip install --upgrade fooof` or
```julia
using PyCall
pip = pyimport("pip")
pip.main(["install", "--upgrade", "FOOOF"])
```

You can test your setup with `using PyCall; pyimport("fooof")`.

## Usage

In the same philosophy as PyCall, this allows for the transparent use of
FOOOF from within Julia.
The major things the package does are wrap the installation of FOOOF in the
package `build` step, load all the FOOOF functionality into the module namespace,
and provide a few accessors.


### Exposing FOOOF in Julia

For example, in Python you can create a new FOOOF model like this:

```python
import fooof

fm = fooof.FOOOF()
```

With PyFOOOF, you can do this from within Julia.

```julia
using PyFOOOF

fm = PyFOOOF.FOOOF()
```

The PyCall infrastructure also means that Python docstrings are available
in Julia:

```julia
help?> PyFOOOF.FOOOF
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

### Helping with type conversions

PyCall can be rather aggressive in converting standard types, such as
dictionaries, to their native Julia equivalents, but this can create problems
due to differences in the way inheritance is traditionally used between
languages.
In particular, Julia arrays are converted to NumPy arrays and *not* Python lists.
This conversion creates problems where FOOOF expects a list and not an array, for example in the `freq_range` keyword argument:

```julia
julia> fm = FOOOF(; peak_width_limits=[1,8])
ERROR: PyError ($(Expr(:escape, :(ccall(#= /home/ubuntu/.julia/packages/PyCall/BD546/src/pyfncall.jl:43 =# @pysym(:PyObject_Call), PyPtr, (PyPtr, PyPtr, PyPtr), o, pyargsptr, kw))))) <class 'ValueError'>
ValueError('The truth value of an array with more than one element is ambiguous. Use a.any() or a.all()')
  File "/home/ubuntu/anaconda3/lib/python3.8/site-packages/fooof/objs/fit.py", line 193, in __init__
    self._reset_internal_settings()
  File "/home/ubuntu/anaconda3/lib/python3.8/site-packages/fooof/objs/fit.py", line 236, in _reset_internal_settings
    if self.peak_width_limits:
```
(The particular problem arises here because FOOOF is depending on the Python's automatic conversion of `None` and empty lists to `False` and non-empty lists to `True`.)

Note that simply wrapping the array as a Python literal (`py"[1,8]"`) does not suffice because this is converted to a Julia vector and thus then to a NumPy array when passed back to Python. Instead, we have to force PyCall to not convert the resulting Python object with the `o` suffix:

```julia
julia> fm = FOOOF(; peak_width_limits=py"[1,8]"o)
PyObject <fooof.objs.fit.FOOOF object at 0x7fea38b5b040>
```

Another conversion problem arises in cases where nesting lists and eltypes creates problems.
For example, the [FOOOF tutorial "Tuning and Troubleshooting"](https://fooof-tools.github.io/fooof/auto_tutorials/plot_07-TroubleShooting.html) includes this statement
```python
gauss_params = [[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]]
```
When executed via PyCall, this results in a Julia `Matrix` with eltype `Real`.

```julia
julia> py"$([[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]])"
PyObject [array([10. ,  1. ,  2.5]), array([20. ,  0.8,  2. ]), array([32. ,  0.6,  1. ])]
julia> py"$([[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]])"
3-element Vector{Vector{Float64}}:
 [10.0, 1.0, 2.5]
 [20.0, 0.8, 2.0]
 [32.0, 0.6, 1.0]
```
This results in an error:
```julia
julia> gen_power_spectrum = fooof.sim.gen.gen_power_spectrum
julia> f_range = [1, 50]
julia> ap_params = [20, 2]
julia> nlv = 0.1
julia> gauss_params = [[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]]
julia> freqs, spectrum = gen_power_spectrum(f_range, ap_params, gauss_params, nlv)
ERROR: PyError ($(Expr(:escape, :(ccall(#= /home/ubuntu/.julia/packages/PyCall/BD546/src/pyfncall.jl:43 =# @pysym(:PyObject_Call), PyPtr, (PyPtr, PyPtr, PyPtr), o, pyargsptr, kw))))) <class 'ValueError'>
ValueError('operands could not be broadcast together with shapes (99,) (3,) ')
...
```

When that line is executed in Python and then roundtripped through Julia, PyCall converts the Python return value to a `Matrix`, which works in the subsequent function call:
```julia
julia> gauss_params = py"[[10, 1.0, 2.5], [20, 0.8, 2], [32, 0.6, 1]]"
3×3 Matrix{Real}:
 10  1.0  2.5
 20  0.8  2
 32  0.6  1
julia> freqs, spectrum = gen_power_spectrum(f_range, ap_params, gauss_params, nlv)
([1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5  …  45.5, 46.0, 46.5, 47.0, 47.5, 48.0, 48.5, 49.0, 49.5, 50.0], [9.112713501760112e19, 6.707288550822094e19, 3.4304395055235047e19, 1.6048034860916263e19, 1.3121468876633584e19, 9.23648446980319e18, 7.068034503219047e18, 7.474675398285033e18, 5.682794734823231e18, 6.002884162025267e18  …  5.494028369147603e16, 5.044411758605143e16, 4.528833513498138e16, 4.080554951080287e16, 4.064069219484658e16, 3.9731296024126536e16, 3.21719026879766e16, 4.828351597256686e16, 4.441592192173848e16, 4.129641670786365e16])
```

However, naively using in Julia a true 2d array (`Matrix`) also results in error:
```julia
julia> gauss_params = [10 1.0 2.5; 20 0.8 2; 32 0.6 1]
3×3 Matrix{Float64}:
 10.0  1.0  2.5
 20.0  0.8  2.0
 32.0  0.6  1.0
julia> freqs, spectrum = gen_power_spectrum(f_range, ap_params, gauss_params, nlv)
\ERROR: PyError ($(Expr(:escape, :(ccall(#= /home/ubuntu/.julia/packages/PyCall/BD546/src/pyfncall.jl:43 =# @pysym(:PyObject_Call), PyPtr, (PyPtr, PyPtr, PyPtr), o, pyargsptr, kw))))) <class 'ValueError'>
ValueError('operands could not be broadcast together with shapes (99,) (3,) '
...
```

The problem is in the eltype: we need to force it to `Real` so that the integers are preserved as integers when passed to Python:

```julia
julia> gauss_params = Real[10 1.0 2.5; 20 0.8 2; 32 0.6 1]
3×3 Matrix{Real}:
 10  1.0  2.5
 20  0.8  2
 32  0.6  1
```

If other automatic type conversions are found to be problematic or there are
particular FOOOF functions that don't play nice via the default PyCall mechanisms,
then issues and pull requests are welcome.

Many of these problematic conversions can be fixed with relatively straightforward (and backward compatible) changes to FOOOF; we are in the process of opening PRs for this purpose.
