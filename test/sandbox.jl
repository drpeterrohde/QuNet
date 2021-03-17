"""
Scratch file for testing with Juno Debugger
"""

using QuNet
using LightGraphs
using SimpleWeightedGraphs

include("network-library/smalltemp.jl")
# Test: greedy_multi_path on a TemporalGraph with 2 asynchronus end-users
T = deepcopy(smalltemp)
offset = smalltemp.nv * smalltemp.steps
src1 = 1 + offset
dst1 = 4 + offset
src2 = 2 + offset
dst2 = 3 + offset
QuNet.add_async_nodes!(T, [(src1, dst1), (src2, dst2)])
pathset, pur_paths, pathuse_count = QuNet.greedy_multi_path!(T, purify, [(src1, dst1), (src2, dst2)])
println(pathset)
