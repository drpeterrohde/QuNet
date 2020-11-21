include("QuNet.jl")

using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors

net = QuNet.GridNetwork(10,10)
temp = QuNet.TemporalGraph(net,3)

g = deepcopy(temp.graph)

paths = QuNet.greedy_multi_path!(g, 20, 50, maxpaths=3)

used_edges = []
for path in paths
    for edge in path
        push!(used_edges, edge)
    end
end

membership = []
for edge in edges(g)
    if edge in used_edges
        push!(membership, 2)
    else
        push!(membership, 1)
    end
end

pal = [colorant"lightgrey", colorant"orange"]
wid = [1 5]
colors = pal[membership]
widths = wid[membership]

gplot(g, edgestrokec=colors, edgelinewidth=widths, arrowlengthfrac=0.04, layout=spring_layout)
#gplot(g, edgestrokec=colors, edgelinewidth=widths, arrowlengthfrac=0.04, layout=spring_layout, nodelabel=1:nv(g))
#gplot(g, arrowlengthfrac=0.04)
