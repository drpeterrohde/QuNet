"""
This file contains all the scripts used to produce the plots for the QuNet paper.
(Except for the Satellite plot which is in SatPlotDemo.jl)
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using DelimitedFiles

"""
Plot the performance statistics of greedy-multi-path vs the number of end-user pairs
"""
function plot_with_userpairs(max_pairs::Int64,
    num_trials::Int64)

    # The average routing costs between end-users sampled over num_trials for different numbers of end-users
    perf_data = []
    # The associated errors of the costs sampled over num_trials
    perf_err = []
    # Average numbers of paths used, sampled over num_trials for different numbers of end-users
    # e.g. [3,4,5]: 3 end-users found no path on average, 4 end-users found 1 path on average etc.
    path_data = []
    # Associated errors of path_data
    path_err = []

    grid_size = 10

    for i in 1:max_pairs
        println("Collecting for pairsize: $i")

        net = GridNetwork(grid_size, grid_size)

        # Collect performance statistics
        p, p_e, pat, pat_e = net_performance(net, num_trials, i)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)

    end

    # Get values for x axis
    x = collect(1:max_pairs)

    # Extract data from performance
    loss = collect(map(x->x["loss"], perf_data))
    z = collect(map(x->x["Z"], perf_data))
    loss_err = collect(map(x->x["loss"], perf_err))
    z_err = collect(map(x->x["Z"], perf_err))

    # Extract data from path: PX is the rate of using X paths
    P0 = [path_data[i][1]/i for i in 1:max_pairs]
    P1 = [path_data[i][2]/i for i in 1:max_pairs]
    P2 = [path_data[i][3]/i for i in 1:max_pairs]
    P3 = [path_data[i][4]/i for i in 1:max_pairs]

    P0e = [path_err[i][1]/i for i in 1:max_pairs]
    P1e = [path_err[i][2]/i for i in 1:max_pairs]
    P2e = [path_err[i][3]/i for i in 1:max_pairs]
    P3e = [path_err[i][4]/i for i in 1:max_pairs]

    # Save data to txt
    open("data/userpairs.txt", "w") do io
        writedlm(io, ["max_pairs = $max_pairs",
        "num_trials = $num_trials",
        "grid_size = $grid_size",
        "perf_data", perf_data,
        "perf_err", perf_err,
        "path_data", path_data,
        "path_err", path_err])
    end

    # Plot
    plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
    legend=:bottomright)
    plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    savefig("plots/cost_userpair.png")
    savefig("plots/cost_userpair.pdf")

    plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
    plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
    plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
    plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    savefig("plots/path_userpair.png")
    savefig("plots/path_userpair.pdf")
end


"""
Plot the performance statistics of greedy-multi-path with respect to edge percolation
rate (The probability that a given edge is removed)
"""
function plot_with_percolations(perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)
    # number of end-user pairs
    num_pairs = 3

    # Network to be percolated.
    grid_size = 10
    net = GridNetwork(grid_size, grid_size)

    perf_data = []
    perf_err = []
    path_data = []
    path_err = []

    for p in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for percolation rate: $p")

        # Percolate the network
        perc_net = QuNet.percolate_edges(net, p)
        refresh_graph!(perc_net)

        # Collect performance data with error
        p, p_e, pat, pat_e = net_performance(perc_net, num_trials, num_pairs)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
    end

    # Get values for x axis
    x = collect(perc_range[1]:perc_range[2]:perc_range[3])

    # Extract performance data
    loss = collect(map(x->x["loss"], perf_data))
    z = collect(map(x->x["Z"], perf_data))
    loss_err = collect(map(x->x["loss"], perf_err))
    z_err = collect(map(x->x["Z"], perf_err))

    # Save data to txt
    open("data/percolation.txt", "w") do io
        writedlm(io, ["perc_range = $perc_range",
        "num_trials = $num_trials",
        "num_pairs = $num_pairs",
        "grid_size = $grid_size",
        "perf_data:", perf_data,
        "perf_err:", perf_err,
        "path_data:", path_data,
        "path_err:", path_err])
    end

    # Extract data from path: PX is the rate of using X paths
    P0 = [path_data[i][1]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P1 = [path_data[i][2]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P2 = [path_data[i][3]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P3 = [path_data[i][4]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]

    # Extract errors from path:
    P0e = [path_err[i][1]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P1e = [path_err[i][2]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P2e = [path_err[i][3]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P3e = [path_err[i][4]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]

    # Plot
    plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
    legend=:bottomright)
    plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")
    xaxis!(L"$\textrm{Probability of Edge Removal}$")
    savefig("plots/cost_percolation.pdf")
    savefig("plots/cost_percolation.png")

    plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
    plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
    plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
    plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
    xaxis!(L"$\textrm{Probability of Edge Removal}$")
    savefig("plots/path_percolation.pdf")
    savefig("plots/path_percolation.png")
end


"""
Plot the performance statistics of greedy-multi-path with respect to the timedepth
of the graph
"""
function plot_with_timedepth(num_trials::Int64, max_depth::Int64)

    """
    For a given grid size, this function runs the greedy_multi_path routing algorithm
    on randomly placed end-user pairs.
    """
    function asymptotic_costs(gridsize::Int64)
        N = 10000
        G = GridNetwork(gridsize, gridsize)
        p, dum1, dum2, dum3 = net_performance(G, N, 1)
        return p["loss"], p["Z"]
    end

    # BEGIN MAIN

    num_pairs = 40
    grid_size = 10

    perf_data = []
    perf_err = []
    path_data = []
    path_err = []

    for i in 1:max_depth
        println("Collecting for time depth $i")
        G = GridNetwork(grid_size, grid_size)
        # Create a Temporal Graph from G with timedepth i
        T = QuNet.TemporalGraph(G, i, memory_costs = unit_costvector())
        # Get random pairs of asynchronus nodes
        user_pairs = make_user_pairs(T, num_pairs)
        # Get data
        p, p_e, pat, pat_e = net_performance(T, num_trials, num_pairs)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
    end

    # Collect data for horizontal lines:
    println("Collecting data for asymptote")
    as = numerical_single_user_multi_path_cost(grid_size)
    e_as = ones(length(1:max_depth)) * as[1]
    f_as = ones(length(1:max_depth)) * as[2]

    # Get values for x axis
    x = collect(1:max_depth)

    # Extract from performance data
    loss = collect(map(x->x["loss"], perf_data))
    z = collect(map(x->x["Z"], perf_data))
    loss_err = collect(map(x->x["loss"], perf_err))
    z_err = collect(map(x->x["Z"], perf_err))

    # Save data to txt
    open("data/temporal.txt", "w") do io
        writedlm(io, ["max_depth = $max_depth",
        "num_trials = $num_trials",
        "num_pairs = $num_pairs",
        "grid_size = $grid_size",
        "perf_data:", perf_data,
        "perf_err:", perf_err,
        "path_data:", path_data,
        "path_err:", path_err])
    end

    # Extract from path data
    P0 = [path_data[i][1]/num_pairs for i in 1:max_depth]
    P1 = [path_data[i][2]/num_pairs for i in 1:max_depth]
    P2 = [path_data[i][3]/num_pairs for i in 1:max_depth]
    P3 = [path_data[i][4]/num_pairs for i in 1:max_depth]

    P0e = [path_err[i][1]/num_pairs for i in 1:max_depth]
    P1e = [path_err[i][2]/num_pairs for i in 1:max_depth]
    P2e = [path_err[i][3]/num_pairs for i in 1:max_depth]
    P3e = [path_err[i][4]/num_pairs for i in 1:max_depth]

    # Plot
    # after seriestype: marker = (5)
    plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
    legend=:bottomright)
    plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")

    # Plot asymptote
    plot!(x, e_as, linestyle=:dot, color=:red, linewidth=2, label=L"$\textrm{Asymptotic single-pair } \eta$")
    plot!(x, f_as, linestyle=:dot, color=:green, linewidth=2, label=L"$\textrm{Asymptotic single-pair } F$")
    xaxis!(L"$\textrm{Time Depth of Tempral Meta-Graph}$")

    savefig("plots/cost_temporal.png")
    savefig("plots/cost_temporal.pdf")

    plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
    plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
    plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
    plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
    xaxis!(L"$\textrm{Time Depth of Temporal Meta-Graph}$")

    savefig("plots/path_temporal.png")
    savefig("plots/path_temporal.pdf")
end


"""
Plot performance statistics of greedy-multi-path with respect to grid size of the network
"""
function plot_with_gridsize(num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
    @assert min_size < max_size
    @assert num_pairs*2 <= min_size^2 "Graph size too small for num_pairs"

    perf_data = []
    perf_err = []
    path_data = []
    path_err = []

    size_list = collect(min_size:1:max_size)
    for i in size_list
        println("Collecting for gridsize: $i")
        # Generate ixi graph:
        net = GridNetwork(i, i)

        # Collect performance statistics
        p, p_e, pat, pat_e = net_performance(net, num_trials, num_pairs)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
    end

    # Get values for x axis
    x = collect(min_size:1:max_size)

    # Extract data from performance
    loss = collect(map(x->x["loss"], perf_data))
    z = collect(map(x->x["Z"], perf_data))
    loss_err = collect(map(x->x["loss"], perf_err))
    z_err = collect(map(x->x["Z"], perf_err))

    # Save data to txt
    open("data/gridsize.txt", "w") do io
        writedlm(io, ["min_size = $min_size",
        "max_size = $max_size",
        "num_trials = $num_trials",
        "num_pairs = $num_pairs",
        "perf_data:", perf_data,
        "perf_err:", perf_err,
        "path_data:", path_data,
        "path_err:", path_err])
    end

    # Extract from path data
    P0 = [path_data[i][1]/num_pairs for i in 1:(max_size-min_size)+1]
    P1 = [path_data[i][2]/num_pairs for i in 1:(max_size-min_size)+1]
    P2 = [path_data[i][3]/num_pairs for i in 1:(max_size-min_size)+1]
    P3 = [path_data[i][4]/num_pairs for i in 1:(max_size-min_size)+1]

    P0e = [path_err[i][1]/num_pairs for i in 1:(max_size-min_size)+1]
    P1e = [path_err[i][2]/num_pairs for i in 1:(max_size-min_size)+1]
    P2e = [path_err[i][3]/num_pairs for i in 1:(max_size-min_size)+1]
    P3e = [path_err[i][4]/num_pairs for i in 1:(max_size-min_size)+1]

    # Plot
    plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
    legend=:bottomright)
    plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")
    xaxis!(L"$\textrm{Grid Size}$")
    savefig("plots/cost_gridsize.png")
    savefig("plots/cost_gridsize.pdf")

    plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
    plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
    plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
    plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
    xaxis!(L"$\textrm{Grid Size}$")
    savefig("plots/path_gridsize.png")
    savefig("plots/path_gridsize.pdf")
end


"""
Plot the performance statistics of greedy_multi_path for 1 random end-user pair
over a range of graph sizes and for different numbers of max_path (1,2,3) (ie. the
maximum number of paths that can be purified by a given end-user pair.)
"""
function plot_maxpaths_with_gridsize(num_trials::Int64, min_size::Int64, max_size::Int64)
    @assert min_size < max_size

    perf_data1 = []
    perf_data2 = []
    perf_data3 = []

    size_list = collect(min_size:1:max_size)
    for (j, data_array) in enumerate([perf_data1, perf_data2, perf_data3])
        println("Collecting for max_paths: $j")
        for i in size_list
            println("Collecting for gridsize: $i")
            # Generate ixi graph:
            net = GridNetwork(i, i)

            # Collect performance statistics
            performance, dummy, dummy, dummy = net_performance(net, num_trials, 1, max_paths=j)
            push!(data_array, performance)
        end
    end

    # Get values for x axis
    x = collect(min_size:1:max_size)

    # Extract data from performance data
    loss_arr1 = collect(map(x->x["loss"], perf_data1))
    z_arr1 = collect(map(x->x["Z"], perf_data1))
    loss_arr2 = collect(map(x->x["loss"], perf_data2))
    z_arr2 = collect(map(x->x["Z"], perf_data2))
    loss_arr3 = collect(map(x->x["loss"], perf_data3))
    z_arr3 = collect(map(x->x["Z"], perf_data3))

    # Save data to txt
    open("data/maxpaths.txt", "w") do io
        writedlm(io, ["min_size = $min_size",
        "max_size = $max_size",
        "num_trials = $num_trials",
        "num_pairs = 1",
        "perf_data1:", perf_data1,
        "perf_data2:", perf_data2,
        "path_data3", perf_data3])
    end

    # Plot
    plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", color = :red, legend=:right)
    plot!(x, z_arr1, linewidth=2, label=L"$F_1$", linestyle=:dash, color =:red)
    plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", color =:blue)
    plot!(x, z_arr2, linewidth=2, label=L"$F_2$", linestyle=:dash, color =:blue)
    plot!(x, loss_arr3, linewidth=2, label=L"$\eta_3$", color =:green)
    plot!(x, z_arr3, linewidth=2, label=L"$F_3$", linestyle=:dash, color =:green)

    xaxis!(L"$\textrm{Grid Size}$")
    savefig("plots/cost_maxpaths.png")
    savefig("plots/cost_maxpaths.pdf")
end

"""
Draw a network with timedepth 1 and the greedy-paths chosen between 3 end user pairs.
"""
function generate_static_plot()
    net = GridNetwork(10,10)
    temp = QuNet.TemporalGraph(net, 3)
    # g = deepcopy(temp.graph["loss"])
    user_paths = QuNet.greedy_multi_pathset!(temp, QuNet.purify, [(1,10),(1,50),(1,99)])
    temp = QuNet.TemporalGraph(net, 3)
    QuNet.plot_network(temp.graph["Z"], user_paths, temp.locs_x, temp.locs_y)
    # QuNet.plot_network(temp, user_paths)
end


"""
Two different temporal plots, one with memory and one without. While varying the
number of end-users, we compare the ratio of the depths of the graphs
"""
function temporal_bandwidth_plot(num_trials::Int64, max_pairs::Int64)

    grid_size = 10
    time_depth = 50

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)
    # Extend in time with memory links:
    T_mem = QuNet.TemporalGraph(G, time_depth, memory_costs = unit_costvector())
    # Extend in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    plot_data = []
    error_data = []
    for i in 1:max_pairs
        println("Collecting for pairs : $i")
        raw_data = []
        for j in 1:num_trials
            # Get i random userpairs. Ensure src nodes are fixed on T=1, dst nodes are asynchronus.
            mem_user_pairs = make_user_pairs(T, i, src_layer=1, dst_layer=-1)
            user_pairs = make_user_pairs(T, i, src_layer=-1, dst_layer=-1)

            # Make copies of the network
            T_mem_copy = deepcopy(T_mem)
            T_copy = deepcopy(T)

            # Add async nodes
            QuNet.add_async_nodes!(T_mem_copy, mem_user_pairs, ϵ=100)
            QuNet.add_async_nodes!(T_copy, user_pairs, ϵ=100)

            # Get pathset data
            pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem_copy, QuNet.purify, mem_user_pairs)
            pathset, dum1, dum2 = QuNet.greedy_multi_path!(T_copy, QuNet.purify, user_pairs)
            # Pathset is an array of vectors containing edges describing paths between end-user pairs
            # Objective: find the largest timedepth used in the pathsets

            max_depth_mem = QuNet.max_timedepth(pathset_mem, T)
            max_depth = QuNet.max_timedepth(pathset, T)

            #DEBUG
            println("max_depth: $max_depth  max_depth_mem: $max_depth_mem")

            # Get the ratio of these two quantities. Add it to data array
            push!(raw_data, max_depth / max_depth_mem )
        end
        # Average the raw data, add it to plot data:
        push!(plot_data, mean(raw_data))
        # Get standard error
        push!(error_data, std(raw_data)/sqrt(num_trials - 1))
    end
    # Plot
    x = collect(1:max_pairs)
    plot(x, plot_data, yerr = error_data)
end


function memory_bandwidth_plot(num_trials::Int64, perc_range::Tuple{Float64, Float64, Float64})

    grid_size = 10
    time_depth = 50
    num_pairs = 40

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)
    # Extend in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    plot_data = []
    error_data = []
    for i in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for memory percolation rate : $i")
        # Extend in time with memory links:
        T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=i, memory_costs = unit_costvector())
        raw_data = []
        for j in 1:num_trials
            # Get i random userpairs. Ensure src nodes are fixed on T=1, dst nodes are asynchronus.
            mem_user_pairs = make_user_pairs(T, num_pairs, src_layer=1, dst_layer=-1)
            user_pairs = make_user_pairs(T, num_pairs, src_layer=-1, dst_layer=-1)

            # Make copies of the network
            T_mem_copy = deepcopy(T_mem)
            T_copy = deepcopy(T)

            # Add async nodes
            QuNet.add_async_nodes!(T_mem_copy, mem_user_pairs, ϵ=100)
            QuNet.add_async_nodes!(T_copy, user_pairs, ϵ=100)

            # Get pathset data
            pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem_copy, QuNet.purify, mem_user_pairs)
            pathset, dum1, dum2 = QuNet.greedy_multi_path!(T_copy, QuNet.purify, user_pairs)
            # Pathset is an array of vectors containing edges describing paths between end-user pairs
            # Objective: find the largest timedepth used in the pathsets

            max_depth_mem = QuNet.max_timedepth(pathset_mem, T)
            max_depth = QuNet.max_timedepth(pathset, T)

            #DEBUG
            println("max_depth: $max_depth  max_depth_mem: $max_depth_mem")

            # Get the ratio of these two quantities. Add it to data array
            push!(raw_data, max_depth / max_depth_mem)
        end

        # Average the raw data, add it to plot data:
        push!(plot_data, mean(raw_data))
        # Get standard error
        push!(error_data, std(raw_data)/sqrt(num_trials - 1))
    end
    # Plot
    x = collect(perc_range[1]:perc_range[2]:perc_range[3])
    plot(x, plot_data, yerr = error_data)
end


"""
As suggested by Nathan:

This plot is essentially identical to the plot_with_timedepth, except that no
multi-path routing is allowed. As expected, the costs do not vary with timedepth,
and seem to be in agreement with average L1 costs.
"""
function plot_nomultipath_with_timedepth(num_trials::Int64, max_depth::Int64)

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

        performance, errors, collisions = net_performance(T, num_trials, user_pairs, true, max_paths=1)
        collision_rate = collisions/(num_trials*num_pairs)
        push!(collision_data, collision_rate)
        push!(perf_data, performance)
        push!(err_data, errors)
    end

    # Collect data for horizontal lines:
    # single-user-single-path
    susp = analytic_single_user_single_path_cost(grid_size)
    e_susp = ones(length(1:max_depth)) * susp[1]
    f_susp = ones(length(1:max_depth)) * susp[2]

    # Get values for x axis
    x = collect(1:max_depth)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Extract error data
    loss_error = collect(map(x->x["loss"], err_data))
    z_error = collect(map(x->x["Z"], err_data))

    # Plot
    plot(x, collision_data, seriestype = :scatter, marker = (5), ylims=(0,1), linewidth=2, label=L"$P$",
    legend=:topright)
    plot!(x, loss_arr, seriestype = :scatter, marker = (5), yerror = loss_error, label=L"$\eta$")
    plot!(x, z_arr, seriestype = :scatter, marker = (5), yerror = z_error, label=L"$F$")

    # Plot horizontal lines
    plot!(x, e_susp, linestyle=:dash, color=:red, label=L"$\textrm{Average path } \eta$")
    plot!(x, f_susp, linestyle=:dash, color=:green, label=L"$\textrm{Average path } F$")

    # DEBUG
    # Plot Peter's line
    n = 10
    peternum = 2n*(n^2-1)/(3*(2n^2-1))
    e_peter = ones(length(1:max_depth)) * dB_to_P(peternum)
    plot!(x, e_susp, linestyle=:dash, label=L"$\textrm{Peter's correction}$")


    xaxis!(L"$\textrm{Time Depth of Temporal Meta-Graph}$")
    savefig("nomultipath.pdf")
    savefig("nomultipath.png")
end


# MAIN
"""
Uncomment functions to reproduce plots from the paper / create your own

Note: Reproducing plots with the default parameters (those used in the paper)
will take between 2 to 12 hours each. Reader beware!
"""
# Usage : (max_pairs::Int64, num_trials::Int64)
# plot_with_userpairs(50, 2000)
# plot_with_userpairs(50, 100)

# Usage : (perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)
# ETA 7 hours
# plot_with_percolations((0.0, 0.01, 0.7), 200000)
# plot_with_percolations((0.0, 0.01, 0.7), 100)

# Usage : (num_trials::Int64, max_depth::Int64)
# plot_with_timedepth(10, 15)

# Usage : (num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
# plot_with_gridsize(100, 40, 10, 150)
# plot_with_gridsize(100, 40, 10, 20)

# Usage : (num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
# plot_maxpaths_with_gridsize(10000, 10, 30)
# plot_maxpaths_with_gridsize(100, 10, 30)

# Usage : (num_trials::Int64, max_pairs::Int64)
# temporal_bandwidth_plot(10, 30)

# Usage : num_trials::Int64, perc_range::Tuple{Float64, Float64, Float64}
# memory_bandwidth_plot(10, (0.0, 0.1, 0.5))

# Usage : None
# generate_static_plot()

# Usage: (num_trials::Int64, max_depth::Int64)
# plot_nomultipath_with_timedepth(10, 10)

# Analytic Calculations
# e, f = analytic_single_user_single_path_cost(10)
# println(e)
# println(f)

# Numerical Calculations
# numerical_single_user_multi_path_cost(10)
