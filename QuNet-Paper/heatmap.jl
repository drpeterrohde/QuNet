using QuNet

grid_size = 10
num_trials = 100
num_pairs = 50

net = GridNetwork(grid_size, grid_size)
#usage:
# (network::Union{QNetwork, QuNet.TemporalGraph},
#    num_trials::Int64, num_pairs::Int64; max_paths=3, src_layer::Int64=-1,
#    dst_layer::Int64=-1, edge_perc_rate=0.0)
coord_list = QuNet.heat_data(net, num_trials, num_pairs, max_paths=4)
println(coord_list)
