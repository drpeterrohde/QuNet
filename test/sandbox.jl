"""
Scratch file for testing with Juno Debugger
"""

using QuNet
using LightGraphs
using SimpleWeightedGraphs

# include("network-library/smalltemp.jl")

function draw_network_routing()
    timedepth = 3
    grid_size = 10

    # Index offset for asynchronus nodes
    off = grid_size^2 * timedepth
    # Choose asynchronus endusers
    userpairs = [(1 + off, 100 + off), (50 + off, 81 + off), (87 + off, 22 + off)]

    net = GridNetwork(grid_size, grid_size)
    T = QuNet.TemporalGraph(net, timedepth, memory_prob=1.0)
    QuNet.add_async_nodes!(T, userpairs)
    T_copy = deepcopy(T)
    user_paths, dum1, dum2 = QuNet.greedy_multi_path!(T_copy, QuNet.purify, userpairs)
    QuNet.plot_network(T.graph["Z"], user_paths, T.locs_x, T.locs_y)
end

draw_network_routing()
