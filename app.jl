using GenieFramework, PlotlyBase, DataFrames, JLD2, BSON
using StippleLatex, StippleDownloads

# load some data to display on the plots on startup
@load "S.jld2" sol_stored

@app begin
    # Reactive variables to hold the component states
    @out states = unknowns_list
    @in selected_states = ["Battery₊i(t)", "Battery₊v(t)", "MPPT₊in₊i(t)"]
    @in T = 1.5
    @in simulate = false
    @private S = sol_stored
    @out plot_data = sol_stored[:, Symbol.(vcat(["Battery₊i(t)", "Battery₊v(t)", "MPPT₊in₊i(t)", "t"]))]
    @out step = diff(sol_stored[:, :t])
    @out xrange = [0.0,1500.0]
    # Reactive handler to run the simulation
    @onbutton simulate begin
        @info "Running simulation..."
        prob = ODEProblem(sys, state_values, (0.0,T*1000), param_values)
        sol = solve(prob,Rosenbrock23());
        step = diff(sol.t)
        S = DataFrame(hcat(sol.u...)', states)
        insertcols!(S, 1, :t => sol.t)
        xrange = [0.0, sol.t[end]]
        selected_states = selected_states
        @info "Simulation completed"
    end
    # Reactive handler to update the plot data
    @onchange selected_states begin
        plot_data = S[:, Symbol.(vcat(selected_states, "t"))]
    end
end

@page("/", "app.jl.html")














load_component("component-props")
load_component("dynamic-plotly")
Stipple.Layout.add_script("components/dynamic-plotly/index.js")
