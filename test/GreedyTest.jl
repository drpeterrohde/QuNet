using QuNet

using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
#net = GridNetwork(10,10)
#temp = QuNet.TemporalGraph(net,1)
#g = deepcopy(temp.graph["loss"])
#user_paths = QuNet.greedy_multi_path!(g, [(20,50),(55,90),(1,15)], maxpaths=3)
#QuNet.plot_network(g, user_paths, temp.locs_x, temp.locs_y)

"""
Plot the performance data of greedy_path for some number of trials
    vs the number of end user pairs
"""
function plot_with_userpairs(max_pairs::Int64,
    num_trials::Int64)

    perf_data = []
    collision_data = []

    for i in 1:max_pairs
        println("Collecting for pairsize: $i")
        performance, collisions = grid_performance(10, num_trials, i)
        collision_rate = collisions/(num_trials*i)
        push!(collision_data, collision_rate)
        push!(perf_data, performance)
    end

    # Get values for x axis
    x = collect(1:max_pairs)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Convert from decibelic to metric form
    loss_arr = 1 .- dB_to_P.(loss_arr)
    z_arr = dB_to_Z.(z_arr)

    # Plot
    plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P_s$",
    legend=:bottomright)
    plot!(x, loss_arr, linewidth=2, label=L"$\eta$")
    plot!(x, z_arr, linewidth=2, label=L"$F$")
    title!(L"$\textrm{Routing Statistics for \"Greedy Path\" on } 10\times 10 \textrm{ Grid Lattice}$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
end


# TODO
function plot_with_percolations(perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)

    # Network to be percolated.
    size = 10
    net = GridNetwork(size, size)

    perf_data = []
    collision_data = []

    for p in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for percolation rate: $p")

        # Percolate the network
        perc_net = QuNet.percolate_edges(net, p)
        refresh_graph!(perc_net)

        # Generate a fixed number of random user pairs
        user_pairs = make_user_pairs(size, 10)

        # Collect performance data (with variance) and collision count
        # TODO: Write something like grid_performance but for plot_with_percolations
        performance, collisions = greedy_multi_path!(net, purify, "loss", user_pairs)
        # TODO: get varience data from greedy_multi_path

        push!(perf_data, performance)
        push!(collision_data, collisions)
    end

    # Get values for x axis
    x = collect(perc_range[1]:perc_range[2]:perc_range[3])

    # Plot
    plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P_s$",
    legend=:bottomright)
end


#TODO plot_collisions_with_timedepth


"""
Returns the average cost and average number of collisions for a number
of end-user pairs.
"""
# TODO Remove this function as soon as net_performance is working.
function grid_performance(size::Int64, num_trials::Int64, num_pairs::Int64=3,
    max_paths::Int64=3)
    total_collisions = 0
    pfmnce_data = []
    for i in 1:num_trials
        net = GridNetwork(size, size)
        refresh_graph!(net)
        # Generate random communication pairs
        user_pairs = make_user_pairs(size, num_pairs)
        net_data, collisions = QuNet.greedy_multi_path!(net, purify, "loss", user_pairs)
        total_collisions += collisions
        # Remove entries containing nothing
        filter!(x->x!=nothing, net_data)
        # Average pfmnce_data
        ave = dict_average(net_data)
        # Add it to network_data
        push!(pfmnce_data, ave)
    end
    pfmnce_data = dict_average(pfmnce_data)
    return pfmnce_data, total_collisions
end


"""
Calculates the average value for each key of a list of dictionaries. Assumes
keys are identica across dictionaries
"""
function dict_average(dict_list)
    avcosts = zero_costvector()
    for cost_type in keys(avcosts)
        costs = collect(map(x->x[cost_type], dict_list))
        avcosts[cost_type] = mean(costs)
    end
    return avcosts
end


"""Generate a list of user_pairs for a lattice grid"""
function make_user_pairs(size, num_pairs)
    @assert size^2 >= num_pairs*2 "Graph space too small"
    rand_space = Array(collect(1:size^2))
    pairs = Vector{Tuple}()
    i = 0
    while i < num_pairs
        idx = rand(1:length(rand_space))
        u = rand_space[idx]
        deleteat!(rand_space, idx)
        idx = rand(1:length(rand_space))
        v = rand_space[idx]
        deleteat!(rand_space, idx)
        chosen_pair = (u, v)
        push!(pairs, chosen_pair)
        i += 1
    end
    return pairs
end

# This is correct 2x2 lattice tends towards 1/3 collisions
# performance, collisions = grid_performance(2, 10000, 2)
# println(performance)
# println(collisions)


# Usage: max_pairs, num_trials
plot_with_userpairs(40, 100)

# Usage: range, num_trials
# plot_with_percolations((0.0,0.1,0.5), 100)
