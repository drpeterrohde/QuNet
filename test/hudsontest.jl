using QuNet
using LightGraphs

# Test: remove_shortest_path! works for temporalgraph
G = GridNetwork(2, 2)
T = QuNet.TemporalGraph(G, 2)
QuNet.add_async_nodes!(T)
removed_path_cost = QuNet.remove_shortest_path!(T, "loss", 1, 2)
println(has_edge(T.graph["loss"], 1, 2) == false)
