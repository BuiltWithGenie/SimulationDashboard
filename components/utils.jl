import GenieFramework.Genie.Renderer.Html: normal_element, register_normal_element
function load_component(name)
    component_code() = [script(read("components/$name.js", String))]
    @deps Main_ReactiveModel component_code
    #= Stipple.register_components(Main_ReactiveModel, name, legacy = true) =#
    register_normal_element("component__props", context = @__MODULE__)
end
