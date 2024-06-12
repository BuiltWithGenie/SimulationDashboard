using GenieFramework, PlotlyBase, DataFrames, JLD2, BSON
using StippleLatex, StippleDownloads
@genietools

# enable TailwindCSS
Stipple.Layout.add_script("https://cdn.tailwindcss.com")
# load some data to display on the plots on startup
@load "S.jld2" sol_stored

@app begin
    # Reactive variables to hold the component states
    @out states = unknowns_list
    @in selected_states = ["Battery₊i(t)", "Battery₊v(t)", "MPPT₊in₊i(t)"]
    @in T = 1.5
    @in simulate = false
    @private S = sol_stored
    # Plots defined using PlotlyJS objects
    # For plots made with Genie Builder, check out the #webinar branch
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
    @in components = component_config
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
    # Handler to push new traces to the plot. Run it when the page is done loading
    # in order to show some data on the plot
    @onchange isready,selected_states begin
        trace[!] = []
        for u in selected_states
            push!(trace,scatter(x=S[!,:t]/1000, y=S[!,u],mode="lines", name=u))
        end
        trace = copy(trace)
    end
    @event uploaded begin
        if ENV["GENIE_ENV"] == "prod"
            @info "Attempted upload in prod"
        else
            notify(__model__, "Upload finished")
            notify(selected_states)
            @info "uploaded"
        end
    end
    # TODO: this only prevents file processing, prevent file uploading in prod
    @onchange fileuploads begin
        if ENV["GENIE_ENV"] == "prod"
            notify(__model__, "Run locally to enable file uploads", :warning)
            rm(fileuploads["path"])
        else
            if ! isempty(fileuploads)
                @info "File was uploaded: " fileuploads
                BSON.@load fileuploads["path"]  solution
                S = solution
                rm(fileuploads["path"])

                fileuploads = Dict{AbstractString,AbstractString}()
            end
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

load_component("dynamic-plotly")
load_component("component-props")
Stipple.Layout.add_script("components/dynamic-plotly/index.js")
