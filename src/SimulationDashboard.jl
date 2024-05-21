module SimulationDashboard
using GenieFramework
using GenieFramework, PlotlyBase, DataFrames, JLD2, BSON
using StippleLatex, Latexify, StippleDownloads

function julia_main()::Cint
    Genie.loadapp()
    Genie.up(async=false)
end
end
