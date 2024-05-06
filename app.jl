#todo when modifying a number from the browser in an input, its type is changed to string int the backdend. perhaps because the number is stored in a dictionary without strict typing
using GenieFramework, PlotlyBase, DataFrames, JLD2, BSON
using StippleLatex, Latexify, StippleDownloads
import Base: length, iterate
include("mppt.jl")

Stipple.Layout.add_script("https://cdn.tailwindcss.com")
Stipple.Layout.add_script("https://cdn.jsdelivr.net/npm/@joint/core@4.0.1/dist/joint.js")

@load "S.jld2" sol_stored

get_parameters(c) = parameters(c) == ModelingToolkit.defaults(c)
length(d::Reactive{Dict{Symbol, Dict{String, Any}}}) = length(d.o.val)
iterate(d::Reactive{Dict{Symbol, Dict{String, Any}}}) = iterate(d.o.val)
to_float(x) = typeof(x) == String ? parse(Float64, x) : x
const default_values = vcat(ModelingToolkit.defaults(sys)..., u0) |> Dict
const component_list = [PV_Input, Power_Input, PV, MPPT, Battery, Load, DC_PV, DC_Battery, Ground_] 
const unknowns_list = map(string, unknowns(sys))

const latex_eqs = Dict(string(c.name) => replace(latexify(equations(c)),"align"=>"aligned") for c in component_list)

component_config = Dict(c.name => 
                        Dict(
                             "name" => string(c.name), 
                             "equations" => replace(latexify(equations(c)),"align"=>"aligned"),
                             "parameters" =>
                             Dict(map(
                                      x-> string(x.first) => x.second, 
                                      collect(
                                              Dict(
                                                   filter(
                                                          x -> any(p -> isequal(p, x.first), parameters(c)),
                                                          ModelingToolkit.defaults(c)
                                                         )
                                                  )
                                             )
                                     )
                                 ),
                             "states" => 
                             Dict(map(
                                      x-> replace(string(x.first), "(t)"=>"", "₊" => "." ) => x.second, 
                                      collect(
                                              Dict(
                                                   filter(
                                                          x -> any(p -> isequal(p, x.first), unknowns(c)),
                                                          ModelingToolkit.defaults(c)
                                                         )
                                                  )
                                             )
                                     ))
                            )
                        for c in component_list)

@app begin
    @in var=0
    @in components = component_config
    @out component_names = [c.name for c in component_list]
    @out equations = latex_eqs
    @out x = collect(1:5000)*1.0
    @out y = zeros(1:500)*1.0
    @out trace=[scatter()]
    @out layout = PlotlyBase.Layout(
                                    Dict{Symbol,Any}(:paper_bgcolor => "rgb(226, 232, 240)",
                                                     :plot_bgcolor => "rgb(226, 232, 240)");
                                    xaxis_title="t (s)",
                                    legend=attr( x=1, y=1.02, yanchor="bottom", xanchor="right", orientation="h",),
                                    xaxis=attr(gridcolor="red", gridwidth=4),
                                    yaxis=attr(gridcolor="red"),
                                    margin=Dict(:l => 10, :r => 10, :b => 10, :t => 10),

                                   )
    @in selected_comp = :Battery
    @out uknowns = unknowns_list
    @in selected_unknown = ["Battery₊v(t)", "MPPT₊in₊i(t)"]
    @in txt = ""
    @in simulate = false
    @in T = 1.5
    @private S = sol_stored
    @in download = false
    @onbutton simulate begin
        @info "Running simulation..."
        param_values = Dict( eval(Meta.parse(c["name"]*"."*string(p.first))) => to_float(p.second) for c in values(components) for p in c["parameters"])
        state_values = Dict( eval(Meta.parse(c["name"]*"."*string(p.first))) => to_float(p.second) for c in values(components) for p in c["states"])
        u0 = [
              Battery.v_s => 0.1,
              Battery.v_f => 0.1,
              Battery.v_soc => 0.3
             ]
        prob = ODEProblem(sys, u0, (0.0,T*1000), param_values)
        sol = solve(prob,Rosenbrock23());
        sol_matrix = hcat(sol.u...)
        S = DataFrame(sol_matrix', unknowns_list)
        insertcols!(S, 1, :t => sol.t)
        notify(__model__.selected_unknown)
        notify(__model__, "Simulation complete")
        @info "Simulation completed"
        # solution = S # calling @save on S causes problems, need to make a non-observable copy
        # BSON.@save "S.bson" solution
    end
    @onchange isready,selected_unknown begin
        trace[!] = []
        for u in selected_unknown
            push!(trace,scatter(x=S[!,:t]/1000, y=S[!,u],mode="lines", name=u))
        end
        trace = copy(trace)
    end

    @event uploaded begin
        notify(__model__, "Upload finished")
        notify(__model__.selected_unknown)
        @info "uploaded"
    end
    @onchange fileuploads begin
        if ! isempty(fileuploads)
            @info "File was uploaded: " fileuploads
            BSON.@load fileuploads["path"]  sol_stored
            S = sol_stored
            rm(fileuploads["path"])

            fileuploads = Dict{AbstractString,AbstractString}()
        end
    end
    @event download begin
        try
            solution = S
            io = IOBuffer()
            BSON.@save io solution
            seekstart(io)
            download_binary(__model__, take!(io), "simulation.bson")
        catch ex
            println("Error during download: ", ex)
        end
    end
end

@page("/", "app.jl.html")

include("components/utils.jl")
load_component("component-props")
register_normal_element("component__props", context = @__MODULE__)
