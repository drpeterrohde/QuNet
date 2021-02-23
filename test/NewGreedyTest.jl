using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using DelimitedFiles

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
        averr[cost_type] = std(costs)/(sqrt(length(costs)))
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

"""
Takes a network as input and return statistics for the graph tested against
many instances of the greedy_multi_path! routing algorithm for some number of
random user pairs
"""
function net_performance(network::QNetwork, num_trials::Int64, num_pairs::Int64,
    with_err::Bool=false)

    total_collisions = 0
    pfmnce_data = []
    path_data = []

    for i in 1:num_trials
        net = deepcopy(network)

        # No need to refresh graph here. GridNetwork is already ready to go
        #refresh_graph!(net)

        # Generate random communication pairs
        user_pairs = make_user_pairs(network, num_pairs)
        # net_data is a c
        net_data, collisions, ave_paths_used = QuNet.greedy_multi_path!(net, purify, user_pairs)
        total_collisions += collisions
        push!(path_data, ave_paths_used)

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
        # Performance data and error
        pfmnce_err = dict_err(pfmnce_data)
        pfmnce_data = dict_average(pfmnce_data)
        # Path data and error
        path_err = std(path_data)
        path_data = mean(path_data)
        return pfmnce_data, pfmnce_err, total_collisions, path_data, path_err
    end

    # Average path_data
    path_data = mean(path_data)
    pfmnce_data = dict_average(pfmnce_data)
    return pfmnce_data, total_collisions, path_data
end


function net_performance(tempgraph::QuNet.TemporalGraph, num_trials::Int64,
    user_pairs::Vector{Tuple}, with_err::Bool=false)

    total_collisions = 0
    pfmnce_data = []

    for i in 1:num_trials
        # Copying network seems like it converts it to QNetwork? Test this
        net = deepcopy(tempgraph)

        net_data, collisions = QuNet.greedy_multi_path!(net, purify, user_pairs)
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
    path_data = []

    for i in 1:max_pairs
        println("Collecting for pairsize: $i")
        # Generate 10x10 graph:
        net = GridNetwork(10, 10)

        # Collect performance statistics
        performance, collisions, ave_paths_used = net_performance(net, num_trials, i)
        collision_rate = collisions/(num_trials*i)
        push!(collision_data, collision_rate)
        push!(perf_data, performance)
        push!(path_data, ave_paths_used)
    end

    # Get values for x axis
    x = collect(1:max_pairs)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Save data to csv
    file = "userpairs.csv"
    writedlm(file,  ["Average number of paths used",
                    path_data, "Efficiency", loss_arr,
                    "Z-dephasing", z_arr], ',')

    # Plot
    plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P$",
    legend=:bottomright)
    plot!(x, loss_arr, linewidth=2, label=L"$\eta$")
    plot!(x, z_arr, linewidth=2, label=L"$F$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    savefig("cost_userpair.png")
    savefig("cost_userpair.pdf")

    plot(x, path_data, linewidth=2, legend=false)
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    yaxis!(L"$\textrm{Average Number of Paths Used Per User Pair}$")
    savefig("path_userpair.png")
    savefig("path_userpair.pdf")
end


function plot_with_percolations(perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)

    # Network to be percolated.
    size = 10
    net = GridNetwork(size, size)

    perf_data = []
    err_data = []
    collision_data = []
    path_data = []
    path_err = []

    for p in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for percolation rate: $p")

        # Percolate the network
        perc_net = QuNet.percolate_edges(net, p)
        refresh_graph!(perc_net)

        # Collect performance data (with variance) and collision count
        num_pairs = 3

        # WARNING possibly deadly line break here
        performance, errors, collisions, ave_paths_used, ave_path_err =
        net_performance(perc_net, num_trials, num_pairs, true)

        # Normalise collisions
        collision_rate = collisions/(num_trials*num_pairs)

        push!(perf_data, performance)
        push!(err_data, errors)
        push!(collision_data, collision_rate)
        push!(path_data, ave_paths_used)
        push!(path_err, ave_path_err)
    end

    # Get values for x axis
    x = collect(perc_range[1]:perc_range[2]:perc_range[3])

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Extract error data
    loss_error = collect(map(x->x["loss"], err_data))
    z_error = collect(map(x->x["Z"], err_data))

    # Possibly redundent here?
    loss_arr = replace(loss_arr, nothing=>NaN)
    z_arr = replace(z_arr, nothing=>NaN)

    # Save data to csv
    file = "percolations.csv"
    writedlm(file,  ["Average number of paths used",
                    path_data, "Efficiency", loss_arr,
                    "Efficiency Error", loss_error,
                    "Z-dephasing", z_arr,
                    "Z Error", z_error], ',')

    # Plot
    #plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P$",
    #legend=:bottomright)
    plot(x, loss_arr, ylims=(0,1), seriestype = :scatter, yerror = loss_error, label=L"$\eta$",
    legend=:bottomright)
    plot!(x, z_arr, seriestype = :scatter, yerror = z_error, label=L"$F$")
    xaxis!(L"$\textrm{Probability of Edge Removal}$")
    savefig("cost_percolation.pdf")
    savefig("cost_percolation.png")

    plot(x, path_data, seriestype = :scatter, yerror = path_err, linewidth=2, legend=false)
    xaxis!(L"$\textrm{Probability of Edge Removal}$")
    yaxis!(L"$\textrm{Average Number of Paths Used Per User Pair}$")
    savefig("path_percolation.pdf")
    savefig("path_percolation.png")
end


"""
Plot the collisions of a grid lattice
"""
function plot_with_timedepth(num_trials::Int64, max_depth::Int64)

    num_pairs = 40
    grid_size = 10

    perf_data = []
    err_data = []
    collision_data = []

    for i in 1:max_depth
        println("Collecting for time depth $i")
        G = GridNetwork(grid_size, grid_size)
        T = QuNet.TemporalGraph(G, i)
        QuNet.add_async_nodes!(T)
        # Get random pairs from G.
        user_pairs = make_user_pairs(G, num_pairs)

        performance, errors, collisions = net_performance(T, num_trials, user_pairs, true)
        collision_rate = collisions/(num_trials*num_pairs)
        push!(collision_data, collision_rate)
        push!(perf_data, performance)
        push!(err_data, errors)
    end

    # Get values for x axis
    x = collect(1:max_depth)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Extract error data
    loss_error = collect(map(x->x["loss"], err_data))
    z_error = collect(map(x->x["Z"], err_data))

    # TODO Figure out why errors are so small?
    # Save data to csv
    file = "temporal.csv"
    writedlm(file,  ["Efficiency", loss_arr,
                    "Efficiency Error", loss_error,
                    "Z-dephasing", z_arr,
                    "Z Error", z_error], ',')

    # Plot
    plot(x, collision_data, seriestype = :scatter, marker = (5), ylims=(0,1), linewidth=2, label=L"$P$",
    legend=:topright)
    plot!(x, loss_arr, seriestype = :scatter, marker = (5), yerror = loss_error, label=L"$\eta$")
    plot!(x, z_arr, seriestype = :scatter, marker = (5), yerror = z_error, label=L"$F$")
    xaxis!(L"$\textrm{Time Depth of Temporal Meta-Graph}$")
    savefig("temporal.pdf")
    savefig("temporal.png")
end

# CODE TO GENERATE STATIC PLOT. LOOKS GOOD!
# net = GridNetwork(10,10)
# temp = QuNet.TemporalGraph(net,1)
# g = deepcopy(temp.graph["loss"])
# user_paths = QuNet.greedy_multi_path!(g, [(20,50),(55,90),(1,15)], maxpaths=3)
# QuNet.plot_network(g, user_paths, temp.locs_x, temp.locs_y)

# MAIN
# plot_with_userpairs(40, 100000)
println("Beginning plot_with_percolations")
plot_with_percolations((0.0, 0.01, 0.7), 100000)
# plot_with_timedepth(500, 20)
