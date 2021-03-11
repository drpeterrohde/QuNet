"""
Scratch file for testing with Juno Debugger
"""

using QuNet
using LightGraphs
using SimpleWeightedGraphs
# include("test/network-library/barbell.jl")

grid_size = 6
time_depth = 500
num_pairs = 16

G = GridNetwork(grid_size, grid_size)
T = QuNet.TemporalGraph(G, time_depth, memory_costs = unit_costvector())
QuNet.add_async_nodes!(T)
user_pairs = make_user_pairs(T, num_pairs)

T_flat = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)
QuNet.add_async_nodes!(T_flat)

function max_timedepth(pathset, T)
    max_depth = 1
    for bundle in pathset
        for path in bundle
            for edge in path
                src = edge.src; dst = edge.dst
                t1 = (src-1) ÷ T.nv
                t2 = (dst-1) ÷ T.nv
                if t1 > max_depth
                    max_depth = t1
                elseif t2 > max_depth
                    max_depth = t2
                end
            end
        end
    end
    return max_depth
end

pathset, dum1, dum2 = QuNet.greedy_multi_path!(T, QuNet.purify, user_pairs)
pathset_flat, dum1, dum2 = QuNet.greedy_multi_path!(T_flat, QuNet.purify, user_pairs)
max_depth = max_timedepth(pathset, T)
max_depth_flat = max_timedepth(pathset, T_flat)

flush(stdout)
# println(pathset)
# println(pathset_flat)

println(length(pathset[4]))

println(max_depth)
println(max_depth_flat)
