#todo when modifying a number from the browser in an input, its type is changed to string int the backdend. perhaps because the number is stored in a dictionary without strict typing
using GenieFramework, PlotlyBase, DataFrames
import Base: length, iterate
include("mppt.jl")
@genietools

Stipple.Layout.add_script("https://cdn.tailwindcss.com")
Stipple.Layout.add_script("https://cdn.jsdelivr.net/npm/@joint/core@4.0.1/dist/joint.js")

cb(integrator) = println("$(integrator.u) $(integrator.t)")
condition(u,t,integrator) = t%1000 == 0
sol = solve(prob,Rosenbrock23(), callback = DiscreteCallback(condition,cb));

#= get_parameters(c) = parameters(c) == Any[] ? [""] : parameters(c) =#
get_parameters(c) = parameters(c) == ModelingToolkit.defaults(c)
length(d::Reactive{Dict{Symbol, Dict{String, Any}}}) = length(d.o.val)
iterate(d::Reactive{Dict{Symbol, Dict{String, Any}}}) = iterate(d.o.val)
to_float(x) = typeof(x) == String ? parse(Float64, x) : x
default_values = vcat(ModelingToolkit.defaults(sys)..., u0)
component_list = [pv_input, power_input, pv, mppt, batter, load, dc_pv, dc_batter, ground]
unknowns_list = map(string, unknowns(sys))

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
Stipple.stipple_parse(::Num,  n::String) = convert(Float64,n) |> Num
Stipple.stipple_parse(n::String,::Num) = convert(Float64,n) |> Num

@app begin
    @in var=0
    @in components = Dict(c.name => 
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
                                                #= (getproperty(c,Symbol(p)),ModelingToolkit.defaults(c)[p]) for p in parameters(c) )  =#
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
                                                #= (getproperty(c,Symbol(p)),ModelingToolkit.defaults(c)[p]) for p in parameters(c) )  =#
                                               )
                                  )
                              ))
                         )
    for c in component_list)
    @out component_names = [c.name for c in component_list]
    @out x = collect(1:5000)*1.0
    @out y = zeros(1:500)*1.0
    @out trace=[scatter()]
    @out layout = PlotlyBase.Layout(
        xaxis_title="t",
        legend=attr(
        x=1,
        y=1.02,
        yanchor="bottom",
        xanchor="right",
        orientation="h"
    ),
    )
    @in selected_comp = :batter
    @out uknowns = unknowns_list
    @in selected_unknown = []
    @in txt = ""
    @in simulate = false
    @in T = 100
    @private S = DataFrame()
    @onchange isready begin
        simulate = true
    end
    @onbutton simulate begin
        param_values = Dict( eval(Meta.parse(c["name"]*"."*string(p.first))) => to_float(p.second) for c in values(components) for p in c["parameters"])
        state_values = Dict( eval(Meta.parse(c["name"]*"."*string(p.first))) => to_float(p.second) for c in values(components) for p in c["states"])
        @show state_values
        u0 = [
              batter.v_s => 0.1,
              batter.v_f => 0.1,
              batter.v_soc => 0.3
             ]
        prob = ODEProblem(sys, u0, (0.0,T), param_values)
        sol = solve(prob,Rosenbrock23(), callback = DiscreteCallback(condition,cb));
        sol_matrix = hcat(sol.u...)
        x = sol.t
        y = sol_matrix[1,:]
        S = DataFrame(sol_matrix', unknowns_list)
        insertcols!(S, 1, :t => collect(1:size(sol_matrix,2)))
        notify(__model__.selected_unknown)
    end
    @onchange selected_unknown begin
        #= trace = [scatter()] =#
        @show S[!,selected_unknown]
        trace[!] = []
        for u in selected_unknown
            push!(trace,scatter(x=S[!,:t], y=S[!,u],mode="lines", name=u))
        end
    trace = copy(trace)
        @show trace
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
