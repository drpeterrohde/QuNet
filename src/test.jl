include("QuNet.jl")

using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors

net = QuNet.GridNetwork(10,10)
temp = QuNet.TemporalGraph(net,1)

g = deepcopy(temp.graph["loss"])

user_paths = QuNet.greedy_multi_path!(g, [(20,50),(55,90),(1,15)], maxpaths=3)
QuNet.plot_network(g, user_paths, temp.locs_x, temp.locs_y)

#gplot(g, edgestrokec=colors, edgelinewidth=widths, arrowlengthfrac=0.04, layout=spring_layout, nodelabel=1:nv(g))
#gplot(g, arrowlengthfrac=0.04)

# QuNet.refresh_graph(net)
# QuNet.percolation_bench(net.graph, 0.1, 100)
