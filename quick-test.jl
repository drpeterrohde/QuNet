using QuNet
using LightGraphs
using SimpleWeightedGraphs
include("test/network-library/smalltemp.jl")

#Test: greedy_multi_path on a TemporalGraph with 2 end-users
T = deepcopy(smalltemp)
QuNet.add_async_nodes!(T)
pathset, pur_paths, pathuse_count = QuNet.greedy_multi_path!(T, purify, [(1,4), (2,3)])
println(pathset)
println(pur_paths)
println(pathuse_count)
