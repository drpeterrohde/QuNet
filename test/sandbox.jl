"""
Scratch file for testing with Juno Debugger
"""

using QuNet
using LightGraphs
using SimpleWeightedGraphs
# include("test/network-library/barbell.jl")

T = deepcopy(smalltemp)
QuNet.add_async_nodes!(T)
performance, performance_err, ave_pathcounts, ave_pathcounts_err = net_performance(T, 100, 2)
println(performance)
println(performance_err)
println(ave_pathcounts)
println(ave_pathcounts_err)
