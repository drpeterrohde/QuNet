using QuNet
using LightGraphs
using SimpleWeightedGraphs
include("test/network-library/smalltemp.jl")

# Test: remove_shortest_path! for a TemporalGraph
T = deepcopy(smalltemp)
QuNet.add_async_nodes!(T)
removed_path_cost = QuNet.remove_shortest_path!(T, "loss", 1, 2)
println(removed_path_cost)
