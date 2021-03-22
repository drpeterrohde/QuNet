using QuNet
using DataFrames
using CSV
using Statistics

# Graph + sampling parameters
grid_size = 100
num_pairs = 50
num_trials = 100
max_paths = 1

# Get the "coordinates" associated with end users
#   that is, the associated efficiency and fidelity of the paths connecting them (if any)
edge_costs = Dict("loss"=>0.05, "Z"=>0.05)
net = GridNetwork(grid_size, grid_size, edge_costs=edge_costs)
#usage:
# (network::Union{QNetwork, QuNet.TemporalGraph},
#    num_trials::Int64, num_pairs::Int64; max_paths=3, src_layer::Int64=-1,
#    dst_layer::Int64=-1, edge_perc_rate=0.0)
coord_list = QuNet.heat_data(net, num_trials, num_pairs, max_paths=max_paths)

# List comprehension to extract data
e = [coord_list[i][1] for i in 1:length(coord_list)]
f = [coord_list[i][2] for i in 1:length(coord_list)]

# # Convert cood_list to data_frame and write to csv
df = DataFrame(Efficiency = e, Fidelity = f)
CSV.write("data/heatmap.csv", df)
# Continue on from heatmap.py to generate the plot


"""
This function gets the end-to-end failure rate (P₀) of the graph in the heatmap
plot. By my calculations, this is about 0.20
"""
function get_P0_for_graph()
    num_trials = 100
    max_paths = 4

    failure_counts = []
    for i in 1:num_trials
        println("num_trial $i")
        edge_costs = Dict("loss"=>0.05, "Z"=>0.05)
        net = GridNetwork(grid_size, grid_size, edge_costs=edge_costs)
        user_pairs = QuNet.make_user_pairs(net, 50)
        pathset, pur_paths, pathuse_count = QuNet.greedy_multi_path!(net, QuNet.purify, user_pairs, 4)
        push!(failure_counts, pathuse_count[1])
    end
    return(mean(failure_counts./num_pairs))
end
