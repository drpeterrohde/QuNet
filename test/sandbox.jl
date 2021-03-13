"""
Scratch file for testing with Juno Debugger
"""

using QuNet
using LightGraphs
using SimpleWeightedGraphs

# Test add_async_nodes!
G = deepcopy(barbell)
T = QuNet.TemporalGraph(G, 3)
async_pairs = make_user_pairs(T, 1)
QuNet.add_async_nodes!(T, async_pairs)

# @test g.weights[2,8] == 0 && g.weights[8,2] != 0


# include("network-library/smalltemp.jl")
# # Test: remove_shortest_path! for a TemporalGraph returning cost vector
# # and using temporal nodes
# T = deepcopy(smalltemp)
# QuNet.add_async_nodes!(T)
# # TODO
# # use asynchronus nodes 1,2 -> index_correcting -> 9, 10
# # async_src = 1 + T.nv * T.steps
# # async_dst = 1 + T.nv * T.steps
# removed_path, removed_cv = QuNet.remove_shortest_path!(T, "loss", 1, 2)
# # Test removed path is correct
# shortestpath = [(1,2)]
# shortestpath = QuNet.int_to_simpleedge(shortestpath)
# @assert(shortestpath == removed_path)
# # Test removed path cost vectors is correct.
# @assert removed_cv["loss"] == 1 && removed_cv["Z"] == 1
#
# # Remove shortest path again, and test that the path in the next temporal layer was removed
# removed_path, removed_cv = QuNet.remove_shortest_path!(T, "loss", 1, 2)
# shortestpath = [(5,6)]
# shortestpath = QuNet.int_to_simpleedge(shortestpath)
# @assert(shortestpath == removed_path)


# NOTE Test max_timedepth
# grid_size = 6
# time_depth = 500
# num_pairs = 16
#
# G = GridNetwork(grid_size, grid_size)
# T = QuNet.TemporalGraph(G, time_depth, memory_costs = unit_costvector())
# QuNet.add_async_nodes!(T)
# user_pairs = make_user_pairs(T, num_pairs)
#
# T_flat = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)
# QuNet.add_async_nodes!(T_flat)
#
# function max_timedepth(pathset, T)
#     max_depth = 1
#     for bundle in pathset
#         for path in bundle
#             for edge in path
#                 src = edge.src; dst = edge.dst
#                 t1 = (src-1) ÷ T.nv
#                 t2 = (dst-1) ÷ T.nv
#                 if t1 > max_depth
#                     max_depth = t1
#                 elseif t2 > max_depth
#                     max_depth = t2
#                 end
#             end
#         end
#     end
#     return max_depth
# end
#
# pathset, dum1, dum2 = QuNet.greedy_multi_path!(T, QuNet.purify, user_pairs)
# pathset_flat, dum1, dum2 = QuNet.greedy_multi_path!(T_flat, QuNet.purify, user_pairs)
# max_depth = max_timedepth(pathset, T)
# max_depth_flat = max_timedepth(pathset, T_flat)
#
# flush(stdout)
# # println(pathset)
# # println(pathset_flat)
#
# println(length(pathset[4]))
#
# println(max_depth)
# println(max_depth_flat)
