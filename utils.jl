import GenieFramework.Genie.Renderer.Html: normal_element, register_normal_element

to_float(x) = typeof(x) == String ? parse(Float64, x) : x


symbolic_dict(components, key) = Dict( eval(Meta.parse(c["name"]*"."*string(p.first))) => to_float(p.second) for c in values(components) for p in c[key])

function load_component(name)
    component_code() = [script(read("components/$name.js", String))]
    @deps Main_ReactiveModel component_code
    #= Stipple.register_components(Main_ReactiveModel, name, legacy = true) =#
    register_normal_element("component__props", context = @__MODULE__)
end

