## System simulation dashboard

A dashboard to simulate one of the examples in the [Ai4EComponentLib.jl](https://ai4energy.github.io) package, which is a library of ModelingToolkit packages. The circuit implements a MPPT controller, which  tracks the maximum voltage current (VI) value so that the system can charge the battery at the maximum power output.

![screenshot](preview.gif)

## Installation

Clone the repository and install the dependencies:

First `cd` into the project directory then run:

```bash
$> julia --project -e 'using Pkg; Pkg.instantiate()'
```

Then run the app

```bash
$> julia --project
```

```julia
julia> using GenieFramework
julia> Genie.loadapp() # load app
julia> up() # start server
```

## Usage

Open your browser and navigate to `http://localhost:8000/`
