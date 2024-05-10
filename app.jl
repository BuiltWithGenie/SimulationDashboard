using GenieFramework, PlotlyBase, DataFrames, JLD2, BSON
using StippleLatex, Latexify, StippleDownloads
include("mppt.jl")
include("utils.jl")

Stipple.Layout.add_script("https://cdn.tailwindcss.com")
Stipple.Layout.add_script("https://cdn.jsdelivr.net/npm/@joint/core@4.0.1/dist/joint.js")

@load "S.jld2" sol_stored


@app begin
    @in var=0
    @in components = component_config
    @out x = collect(1:5000)*1.0
    @out y = zeros(1:500)*1.0
    @out trace=[scatter()]
    @in selected_comp = :Battery
    @out uknowns = unknowns_list
    @in selected_unknown = ["Battery₊v(t)", "MPPT₊in₊i(t)"]
    @in simulate = false
    @in T = 1.5
    @out S = sol_stored
    @in download = false
    @onbutton simulate begin
        @info "Running simulation..."
        param_values = symbolic_dict(components, "parameters")
        state_values = symbolic_dict(components, "states")
        prob = ODEProblem(sys, state_values, (0.0,T*1000), param_values)
        sol = solve(prob,Rosenbrock23());
        sol_matrix = hcat(sol.u...)
        S = DataFrame(sol_matrix', unknowns_list)
        insertcols!(S, 1, :t => sol.t)
        notify(__model__.selected_unknown)
        notify(__model__, "Simulation complete")
        @info "Simulation completed"
    end
    @onchange isready,selected_unknown begin
        trace[!] = []
        for u in selected_unknown
            push!(trace,scatter(x=S[!,:t]/1000, y=S[!,u],mode="lines", name=u))
        end
        trace = copy(trace)
    end
end

@page("/", "app.jl.html")

load_component("component-props")
