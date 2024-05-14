using GenieFramework, PlotlyBase, DataFrames, JLD2, BSON
using StippleLatex, StippleDownloads

# load some data to display on the plots on startup
@load "S.jld2" sol_stored

@app begin
    # Reactive variables to hold the component states
    @out states = unknowns_list
    @in selected_states = ["Battery₊v(t)", "MPPT₊in₊i(t)"]
    @in T = 0.01
    @in simulate = false
    @private S = sol_stored
    @out plot_data = sol_stored
    @out t = collect(1:10)*1.0
    # ---------------------
    @in components = component_config
    # # Reactive handler to run the simulation
    @onchange simulate begin
        @info "Running simulation..."
        param_values = symbolic_dict(components, "parameters")
        state_values = symbolic_dict(components, "states")
        prob = ODEProblem(sys, state_values, (0.0,T*1000), param_values)
        sol = solve(prob,Rosenbrock23());
        S = DataFrame(hcat(sol.u...)', states)
        t = sol.t
        selected_states = selected_states
        @info "Simulation completed"
    end
    # Reactive handler to update the plot data
    @onchange selected_states begin
    # something with plot_data
    @show selected_states
    end
end

@page("/", "app.jl.html")

load_component("component-props")
