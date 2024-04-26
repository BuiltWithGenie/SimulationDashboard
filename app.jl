#todo when modifying a number from the browser in an input, its type is changed to string int the backdend. perhaps because the number is stored in a dictionary without strict typing
using GenieFramework, PlotlyBase, DataFrames, JLD2
using StippleLatex, Latexify
import Base: length, iterate
include("mppt.jl")
@genietools

Stipple.Layout.add_script("https://cdn.tailwindcss.com")
Stipple.Layout.add_script("https://cdn.jsdelivr.net/npm/@joint/core@4.0.1/dist/joint.js")

@load "S.jld2" sol_stored

#= cb(integrator) = println("$(integrator.u) $(integrator.t)") =#
#= condition(u,t,integrator) = t%1000 == 0 =#
#= sol = solve(prob,Rosenbrock23(), callback = DiscreteCallback(condition,cb)); =#

#= get_parameters(c) = parameters(c) == Any[] ? [""] : parameters(c) =#
get_parameters(c) = parameters(c) == ModelingToolkit.defaults(c)
length(d::Reactive{Dict{Symbol, Dict{String, Any}}}) = length(d.o.val)
iterate(d::Reactive{Dict{Symbol, Dict{String, Any}}}) = iterate(d.o.val)
to_float(x) = typeof(x) == String ? parse(Float64, x) : x
default_values = vcat(ModelingToolkit.defaults(sys)..., u0) |> Dict
component_list = [PV_Input, Power_Input, PV, MPPT, Battery, Load, DC_PV, DC_Battery, Ground_] 
unknowns_list = map(string, unknowns(sys))

latex_eqs = Dict(string(c.name) => replace(latexify(equations(c)),"align"=>"aligned") for c in component_list)

function build_param_dict(components)
    prob_params = []
    for c in values(components)
        for p in c["parameters"]
            push!(prob_params, p )
        end
    end
    prob_params
end

#= Stipple.render(v::SymbolicUtils.BasicSymbolic{Real}) = string(v) =#
#= Stipple.stipple_parse(::String, v::SymbolicUtils.BasicSymbolic{Real}) = string(v) =#
#= Stipple.stipple_parse(::Num,  n::String) = convert(Float64,n) |> Num =#
#= Stipple.stipple_parse(n::String,::Num) = convert(Float64,n) |> Num =#
component_config = Dict(c.name => 
                          Dict(
                               "name" => string(c.name), 
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
        legend=attr(
        x=1,
        y=1.02,
        yanchor="bottom",
        xanchor="right",
        orientation="h",
    ),
         xaxis=attr(gridcolor="red", gridwidth=4),
         yaxis=attr(gridcolor="red"),
                             margin=Dict(:l => 10, :r => 10, :b => 10, :t => 10),

    )
    @in selected_comp = :Battery
    @out uknowns = unknowns_list
    @in selected_unknown = ["Battery₊v(t)", "MPPT₊in₊i(t)"]
    @in txt = ""
    @in simulate = false
    @in T = 0.1
    @private S = sol_stored
    @onbutton simulate begin
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
        sol_stored = S
        insertcols!(S, 1, :t => sol.t)
        #= @save "S.jld2" sol_stored =#
        notify(__model__.selected_unknown)
    end
    @onchange isready,selected_unknown begin
        @show selected_unknown
        #= trace = [scatter()] =#
        trace[!] = []
        for u in selected_unknown
            push!(trace,scatter(x=S[!,:t]/1000, y=S[!,u],mode="lines", name=u))
        end
    trace = copy(trace)
    end

    #= @in u = [] =#
    #= @onchange isready begin =#
    #=     sol = solve(prob,Rosenbrock23()) =#
    #= end =#

end

ui() = [
        #= select(:selected_comp, options=:components, label="Component"), cell(@recur("c in components"),[textfield(var"v-model"="c", var":label"="c", var":name"="c")]) =#
        plot(:trace),
        btn("Simulate", @click(:simulate)),
        select(:selected_comp, options=:component_names, label="Component"),
        cell(class="flex", [
                            cell(class = "w-1/2", [ h5("Parameters"),
                                                   cell(class="w-1/2",@recur("(val,p) in components[selected_comp]['parameters']"),[textfield(var"v-model"="components[selected_comp]['parameters'][p]", var":label"="p", type="number")])]),
                            cell(class="w-1/2", [h5("Initial values"),p("")]),
       ])
       ]
#= @page("/",ui) =#
@page("/", "app.jl.html")

