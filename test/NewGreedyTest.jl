using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings

"""
Takes a network as input and return statistics for the graph tested against
many instances of the greedy_multi_path! routing algorithm for some number of
random user pairs
"""
function net_performance(network::QNetwork, num_trials::Int64, num_pairs::Int64,
    with_err::Bool=false)

    total_collisions = 0
    pfmnce_data = []

    for i in 1:num_trials
        net = deepcopy(network)
        refresh_graph!(net)

        # Generate random communication pairs
        user_pairs = make_user_pairs(network, num_pairs)
        # net_data is a c
        net_data, collisions = QuNet.greedy_multi_path!(net, purify, "loss", user_pairs)
        total_collisions += collisions

        # If net_data contains nothing,
        filter!(x->x!=nothing, net_data)

        # Mean well defined only if data set > 0
        if length(net_data) > 0
            # Average the data
            ave = dict_average(net_data)
            push!(pfmnce_data, ave)
        end
    end

    if with_err == true
        # Standard error well defined only if sample size greater than 1
        pfmnce_err = dict_err(pfmnce_data)
        pfmnce_data = dict_average(pfmnce_data)
        return pfmnce_data, pfmnce_err, total_collisions
    end

    pfmnce_data = dict_average(pfmnce_data)
    return pfmnce_data, total_collisions
end


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
        # Generate 10x10 graph:
        net = GridNetwork(10, 10)

        # Collect performance statistics
        performance, collisions = net_performance(net, num_trials, i)
        collision_rate = collisions/(num_trials*i)
        push!(collision_data, collision_rate)
        push!(perf_data, performance)
    end

    # Get values for x axis
    x = collect(1:max_pairs)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Plot
    plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P_s$",
    legend=:bottomright)
    plot!(x, loss_arr, linewidth=2, label=L"$\eta$")
    plot!(x, z_arr, linewidth=2, label=L"$F$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
end


"""
Return average average value for an array of cost vectors.
If the length of the input is less than 1, mean is not well defined,
the key values returned are 'nothing'.
"""
function dict_average(dict_list)
    avcosts = zero_costvector()

    if length(dict_list) == 0
        for cost_type in keys(avcosts)
            avcosts[cost_type] = NaN
        end
        return avcosts
    end

    for cost_type in keys(avcosts)
        costs = collect(map(x->x[cost_type], dict_list))
        avcosts[cost_type] = mean(costs)
    end
    return avcosts
end

"""
Return average standard error for an array of cost vectors.
If the length of the input is less than 2, error is not well defined,
the key values returned are 'nothing'.
"""
function dict_err(dict_list)
    averr = zero_costvector()
    len = length(dict_list)

    if len < 2
        for cost_type in keys(averr)
            averr[cost_type] = NaN
        end
        return averr
    end

    for cost_type in keys(averr)
        costs = collect(map(x->x[cost_type], dict_list))
        averr[cost_type] = std(costs) / sqrt(len - 1)
    end
    return averr
end


"""Generate a list of user_pairs for a QNetwork"""
function make_user_pairs(QNetwork, num_pairs)
    num_nodes = length(QNetwork.nodes)
    @assert num_nodes >= num_pairs*2 "Graph space too small for number of pairs"
    rand_space = Array(collect(1:num_nodes))
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


# TODO
function plot_with_percolations(perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)

    # Network to be percolated.
    size = 10
    net = GridNetwork(size, size)

    perf_data = []
    err_data = []
    collision_data = []

    for p in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for percolation rate: $p")

        # Percolate the network
        perc_net = QuNet.percolate_edges(net, p)
        refresh_graph!(perc_net)

        # Collect performance data (with variance) and collision count
        num_pairs = 10

        #performance, errors, collisions
        performance, errors, collisions = net_performance(perc_net, num_trials, num_pairs, true)

        # Normalise collisions
        collision_rate = collisions/(num_trials*num_pairs)

        push!(perf_data, performance)
        push!(err_data, errors)
        push!(collision_data, collision_rate)
    end

    # Get values for x axis
    x = collect(perc_range[1]:perc_range[2]:perc_range[3])

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Extract error data
    loss_error = collect(map(x->x["loss"], err_data))
    z_error = collect(map(x->x["Z"], err_data))

    # DEBUG
    println(loss_error)
    println(z_error)

    # TODO replace nothing with nan
    loss_arr = replace(loss_arr, nothing=>NaN)
    z_arr = replace(z_arr, nothing=>NaN)

    # Plot
    plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P$",
    legend=:bottomright)
    plot!(x, loss_arr, seriestype = :scatter, yerror = loss_error, label=L"$\eta$")
    plot!(x, z_arr, seriestype = :scatter, yerror = z_error, label=L"$F$")
    #xaxis!(L"$\textrm{Number of End User Pairs}$")
end

# TODO
"""
function plot_collisions_with_timedepth(network::QNetwork, num_trials::Int64,
    num_pairs::Int64, max_depth::Int64)

    for i in 1:max_depth
        # Get enduser pairs
        # Extend network in time
        tempgraph = TemporalGraph(network, i)
        # Write a Temporal Graph function that makes ancilla nodes for each
        # enduser
        # Collect statistics
"""


# Q = GridNetwork(10, 10)
# Usage: QNetwork, num_trials, num_pairs
# result = net_performance(Q, 100, 1, true)
# println(result)

# plot_with_userpairs(40, 100)
plot_with_percolations((0.0, 0.05, 0.9), 100)
