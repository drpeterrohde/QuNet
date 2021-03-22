using QuNet
using DataFrames
using CSV

grid_size = 10
num_trials = 1000
num_pairs = 50

net = GridNetwork(grid_size, grid_size)
#usage:
# (network::Union{QNetwork, QuNet.TemporalGraph},
#    num_trials::Int64, num_pairs::Int64; max_paths=3, src_layer::Int64=-1,
#    dst_layer::Int64=-1, edge_perc_rate=0.0)
coord_list = QuNet.heat_data(net, num_trials, num_pairs, max_paths=4)

# List comprehension
e = [coord_list[i][1] for i in 1:length(coord_list)]
f = [coord_list[i][2] for i in 1:length(coord_list)]
# # Convert cood_list to data_frame and write to csv
df = DataFrame(Efficiency = e, Fidelity = f)
CSV.write("data/heatmap.csv", df)
