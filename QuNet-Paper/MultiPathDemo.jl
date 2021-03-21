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
        p, p_e, pat, pat_e = net_performance(net, num_trials, i, max_paths=4)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)

    end

    # Collect data for conditional probability of purification: (N2+N3)/∑N_i
    cpp = []
    cpp_err = []
    for i in 1:max_pairs
        tableau = path_data[i]
        errors = path_err[i]
        off = 1

        # Numerator and denominator
        num = tableau[2 + off] + tableau[3 + off] + tableau[4 + off]
        denom = tableau[1 + off] + tableau[2 + off] + tableau[3 + off] + tableau[4 + off]

        # Percentage errors (Ignore factor 100. Not needed)
        num_perr = (errors[2 + off] + errors[3 + off] + errors[4 + off])/num
        denom_perr = (errors[1 + off] + errors[2 + off] + errors[3 + off] + errors[4 + off])/denom

        data = num/denom
        data_err = (num_perr + denom_perr) * data
        push!(cpp, data)
        push!(cpp_err, data_err)
        i += 1
    end

    # Collect data for average number of paths used
    avepath = []
    for i in 1:max_pairs
        tableau = convert(Vector{Float64}, path_data[i])
        data = QuNet.ave_paths_used(tableau)

        # TODO: Include errors
        push!(avepath, data)
        i += 1
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
    P4 = [path_data[i][5]/i for i in 1:max_pairs]

    P0e = [path_err[i][1]/i for i in 1:max_pairs]
    P1e = [path_err[i][2]/i for i in 1:max_pairs]
    P2e = [path_err[i][3]/i for i in 1:max_pairs]
    P3e = [path_err[i][4]/i for i in 1:max_pairs]
    P4e = [path_err[i][5]/i for i in 1:max_pairs]

    # Save data to txt
    open("data/userpairs.txt", "w") do io
        writedlm(io, ["max_pairs = $max_pairs",
        "num_trials = $num_trials",
        "grid_size = $grid_size",
        "perf_data", perf_data,
        "perf_err", perf_err,
        "path_data", path_data,
        "path_err", path_err,
        "cpp", cpp,
        "cpp_err", cpp_err,
        "avepath", avepath])
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
    plot!(x, P4, linewidth=2, yerr = P4e, label=L"$P_4$")
    plot!(x, cpp, linewidth=2, yerr = cpp_err, label=L"$P_{P}$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    savefig("plots/path_userpair.png")
    savefig("plots/path_userpair.pdf")

    plot(x, avepath, linewidth=2, legend = false)
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    yaxis!(L"$\textrm{Average Number of Paths Used}$")
    savefig("plots/avepath_userpair.png")
    savefig("plots/avepath_userpair.pdf")
end


"""
Plot the performance statistics of greedy-multi-path with respect to edge percolation
rate (The probability that a given edge is removed)
"""
function plot_with_percolations(perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)
    # number of end-user pairs
    num_pairs = 1

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
        # perc_net = QuNet.percolate_edges(net, p)
        # refresh_graph!(perc_net)

        # Collect performance data with error, percolating the network edges
        p, p_e, pat, pat_e = net_performance(net, num_trials, num_pairs, max_paths=4,
        edge_perc_rate = p)
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
    P4 = [path_data[i][5]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]

    # Extract errors from path:
    P0e = [path_err[i][1]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P1e = [path_err[i][2]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P2e = [path_err[i][3]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P3e = [path_err[i][4]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P4e = [path_err[i][5]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]

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
    plot!(x, P4, linewidth=2, yerr = P3e, label=L"$P_4$")
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
        T = QuNet.TemporalGraph(G, 5, memory_costs = unit_costvector())
        p, dum1, dum2, dum3 = net_performance(T, N, 1, max_paths=4)
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
        p, p_e, pat, pat_e = net_performance(T, num_trials, num_pairs, max_paths=4)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
    end

    # Collect data for horizontal lines:
    println("Collecting data for asymptote")
    as = asymptotic_costs(grid_size)
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
        "path_err:", path_err,
        "e_as", e_as,
        "f_as", f_as])
    end

    # Extract from path data
    P0 = [path_data[i][1]/num_pairs for i in 1:max_depth]
    P1 = [path_data[i][2]/num_pairs for i in 1:max_depth]
    P2 = [path_data[i][3]/num_pairs for i in 1:max_depth]
    P3 = [path_data[i][4]/num_pairs for i in 1:max_depth]
    P4 = [path_data[i][5]/num_pairs for i in 1:max_depth]

    P0e = [path_err[i][1]/num_pairs for i in 1:max_depth]
    P1e = [path_err[i][2]/num_pairs for i in 1:max_depth]
    P2e = [path_err[i][3]/num_pairs for i in 1:max_depth]
    P3e = [path_err[i][4]/num_pairs for i in 1:max_depth]
    P4e = [path_err[i][5]/num_pairs for i in 1:max_depth]

    # Plot
    # after seriestype: marker = (5)
    plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
    legend=:right)
    plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")

    # Plot asymptote
    plot!(x, e_as, linestyle=:dot, color=:red, linewidth=2, label=L"$\textrm{Asymptotic } \eta$")
    plot!(x, f_as, linestyle=:dot, color=:green, linewidth=2, label=L"$\textrm{Asymptotic } F$")
    xaxis!(L"$\textrm{Time Depth of Tempral Meta-Graph}$")

    savefig("plots/cost_temporal.png")
    savefig("plots/cost_temporal.pdf")

    plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
    plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
    plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
    plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
    plot!(x, P4, linewidth=2, yerr = P4e, label=L"$P_4$")
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
        p, p_e, pat, pat_e = net_performance(net, num_trials, num_pairs, max_paths=4)
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
    P4 = [path_data[i][5]/num_pairs for i in 1:(max_size-min_size)+1]

    P0e = [path_err[i][1]/num_pairs for i in 1:(max_size-min_size)+1]
    P1e = [path_err[i][2]/num_pairs for i in 1:(max_size-min_size)+1]
    P2e = [path_err[i][3]/num_pairs for i in 1:(max_size-min_size)+1]
    P3e = [path_err[i][4]/num_pairs for i in 1:(max_size-min_size)+1]
    P4e = [path_err[i][5]/num_pairs for i in 1:(max_size-min_size)+1]

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
    plot!(x, P4, linewidth=2, yerr = P4e, label=L"$P_4$")
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
    perf_data4 = []

    size_list = collect(min_size:1:max_size)
    for (j, data_array) in enumerate([perf_data1, perf_data2, perf_data3, perf_data4])
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
    loss_arr4 = collect(map(x->x["loss"], perf_data4))
    z_arr4 = collect(map(x->x["Z"], perf_data4))

    # Save data to txt
    open("data/maxpaths.txt", "w") do io
        writedlm(io, ["min_size = $min_size",
        "max_size = $max_size",
        "num_trials = $num_trials",
        "num_pairs = 1",
        "perf_data1:", perf_data1,
        "perf_data2:", perf_data2,
        "perf_data3", perf_data3,
        "perf_data4", perf_data4])
    end

    # Plot
    plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", xlims=(0, max_size), color = :red, legend=:left)
    plot!(x, z_arr1, linewidth=2, label=L"$F_1$", linestyle=:dash, color =:red)
    plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", color =:blue)
    plot!(x, z_arr2, linewidth=2, label=L"$F_2$", linestyle=:dash, color =:blue)
    plot!(x, loss_arr3, linewidth=2, label=L"$\eta_3$", color =:green)
    plot!(x, z_arr3, linewidth=2, label=L"$F_3$", linestyle=:dash, color =:green)
    plot!(x, loss_arr4, linewidth=2, label=L"$\eta_3$", color =:purple)
    plot!(x, z_arr4, linewidth=2, label=L"$F_3$", linestyle=:dash, color =:purple)
    xaxis!(L"$\textrm{Grid Size}$")

    savefig("plots/cost_maxpaths.png")
    savefig("plots/cost_maxpaths.pdf")
end

"""
Draw a network with timedepth 1 and the greedy-paths chosen between 3 end user pairs.
"""
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


"""
Two different temporal plots, one with memory and one without. While varying the
number of end-users, we compare the ratio of the depths of the graphs
"""
function plot_bandwidth_ratio_with_userpairs(num_trials::Int64, max_pairs::Int64)

    grid_size = 10
    time_depth = 50
    asynchronus_weight = 100

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
            QuNet.add_async_nodes!(T_mem_copy, mem_user_pairs, ϵ=asynchronus_weight)
            QuNet.add_async_nodes!(T_copy, user_pairs, ϵ=asynchronus_weight)

            # Get pathset data
            pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem_copy, QuNet.purify, mem_user_pairs, 4)
            pathset, dum1, dum2 = QuNet.greedy_multi_path!(T_copy, QuNet.purify, user_pairs, 4)
            # Pathset is an array of vectors containing edges describing paths between end-user pairs
            # Objective: find the largest timedepth used in the pathsets

            max_depth_mem = QuNet.max_timedepth(pathset_mem, T)
            max_depth = QuNet.max_timedepth(pathset, T)

            # Get the ratio of these two quantities. Add it to data array
            push!(raw_data, max_depth / max_depth_mem )
        end
        # Average the raw data, add it to plot data:
        push!(plot_data, mean(raw_data))
        # Get standard error
        push!(error_data, std(raw_data)/sqrt(num_trials - 1))
    end

    # Save data to txt
    open("data/bandwidth_with_userpairs.txt", "w") do io
        writedlm(io, ["grid_size = $grid_size",
        "num_trials = $num_trials",
        "time_depth = $time_depth",
        "max_pairs = $max_pairs",
        "asynchronus_weight = $asynchronus_weight",
        "bandwidth_ratios = $plot_data",
        "bandwidth_error = $error_data"])
    end

    # Plot
    x = collect(1:max_pairs)
    plot(x, plot_data, yerr = error_data, legend = false)
    xaxis!(L"$\textrm{Number of End User Pairs}$")

    savefig("plots/bandwidth_with_userpairs.png")
    savefig("plots/bandwidth_with_userpairs.pdf")
end


# For this one, let's just consider bandwidth. No ratio needed!
function plot_bandwidth_ratio_with_memory_rate(num_trials::Int64, perc_range::Tuple{Float64, Float64, Float64})

    grid_size = 10
    time_depth = 8
    num_pairs = 50
    asynchronus_weight = 100

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)

    # Extend graph in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    plot_data = []
    error_data = []
    for i in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for memory percolation rate : $i")
        raw_data = []
        for j in 1:num_trials

            # Make a network with some probability of memory
            T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=i, memory_costs = unit_costvector())
            # Make a copy of the network without memory
            T_copy = deepcopy(T)

            # Get i random userpairs with asynchronus src and dst nodes.
            mem_user_pairs = make_user_pairs(T_mem, num_pairs, src_layer=-1, dst_layer=-1)
            user_pairs = make_user_pairs(T, num_pairs, src_layer=-1, dst_layer=-1)

            # Add async nodes
            QuNet.add_async_nodes!(T_mem, mem_user_pairs, ϵ=asynchronus_weight)
            QuNet.add_async_nodes!(T_copy, user_pairs, ϵ=asynchronus_weight)

            # Get pathset data
            pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem, QuNet.purify, mem_user_pairs, 1)
            pathset, dum1, dum2 = QuNet.greedy_multi_path!(T_copy, QuNet.purify, user_pairs, 1)
            # Pathset is an array of vectors containing edges describing paths between end-user pairs
            # Objective: find the largest timedepth used in the pathsets

            max_depth_mem = QuNet.max_timedepth(pathset_mem, T_mem)
            max_depth = QuNet.max_timedepth(pathset, T_copy)

            # Get the bandwidth of this quantity
            push!(raw_data, max_depth / max_depth_mem)
        end

        # Average the raw data, add it to plot data:
        push!(plot_data, mean(raw_data))
        # Get standard error
        push!(error_data, std(raw_data)/sqrt(num_trials - 1))
    end

    open("data/bandwidth_with_memory_rate.txt", "w") do io
        writedlm(io, ["grid_size = $grid_size",
        "num_trials = $num_trials",
        "time_depth = $time_depth",
        "num_pairs = $num_pairs",
        "perc_range = $perc_range",
        "asynchronus_weight = $asynchronus_weight",
        "bandwidth_ratios = $plot_data",
        "bandwidth_error = $error_data"])
    end

    # Plot
    x = collect(perc_range[1]:perc_range[2]:perc_range[3])
    plot(x, plot_data, yerr = error_data, legend = false)
    xaxis!(L"$\textrm{Proportion of Nodes with Quantum Memory}$")
    yaxis!(L"$\textrm{R}$")

    savefig("plots/bandwidth_with_memory_rate.png")
    savefig("plots/bandwidth_with_memory_rate.pdf")
end



# MAIN
"""
Uncomment functions to reproduce plots from the paper / create your own
"""
# Usage : (max_pairs::Int64, num_trials::Int64)
# plot_with_userpairs(50, 5000)

# Usage : (perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)
# plot_with_percolations((0.0, 0.01, 0.7), 5000)

# Usage : (num_trials::Int64, max_depth::Int64)
# plot_with_timedepth(1000, 15)

# Usage : (num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
# plot_with_gridsize(100, 40, 10, 150)

# Usage : (num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
# plot_maxpaths_with_gridsize(5000, 10, 50)

# Usage : (num_trials::Int64, max_pairs::Int64)
# plot_bandwidth_ratio_with_userpairs(1000, 50)

# Usage : num_trials::Int64, perc_range::Tuple{Float64, Float64, Float64}
# plot_bandwidth_ratio_with_memory_rate(5000, (0.0, 0.05, 1.0))

# Usage : None
# draw_network_routing()

# Usage: (num_trials::Int64, max_depth::Int64)
# plot_nomultipath_with_timedepth(10, 10)
