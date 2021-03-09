using QuNet
using LightGraphs
using SimpleWeightedGraphs

Q = GridNetwork(10, 10)
userpairs = make_user_pairs(Q, 50)
pathset, purpaths, pathuse_count = QuNet.greedy_multi_path!(Q, purify, userpairs)
println(pathuse_count)
