include("QuNet.jl")

using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors

net = QuNet.GridNetwork(10,10)
# temp = QuNet.TemporalGraph(net,1)

g = deepcopy(net.graph)

user_paths = QuNet.greedy_multi_path!(g, [(20,50),(55,90),(1,15)], maxpaths=3)
QuNet.plot_network(g, user_paths)

#gplot(g, edgestrokec=colors, edgelinewidth=widths, arrowlengthfrac=0.04, layout=spring_layout, nodelabel=1:nv(g))
#gplot(g, arrowlengthfrac=0.04)
