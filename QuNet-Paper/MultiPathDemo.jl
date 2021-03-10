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
    # Spectograms of the average number of paths used in the routing strategy, sampled over num_trials
    # for different numbers of end-users
    # i.e. [3,4,5]: 3 end-users found no path on average, 4 end-users found 1 path on average etc.
    path_data = []
    # Associated errors of path_data
    path_err = []

    for i in 1:max_pairs
        println("Collecting for pairsize: $i")
        # Generate 10x10 graph:
        net = GridNetwork(10, 10)

        # Collect performance statistics
        p, p_e, pat, pat_e = net_performance(net, num_trials, i)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)


        # collision_rate = collisions/(num_trials*i)
        # push!(collision_data, collision_rate)
        # push!(perf_data, performance)
        # push!(path_data, ave_paths_used)
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

    # Save data to csv
    # file = "userpairs.csv"
    # writedlm(file,  ["Average number of paths used",
    #                 path_data, "Efficiency", loss_arr,
    #                 "Z-dephasing", z_arr], ',')

    # Plot
    # plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P$", legend=:bottomright)

    plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
    legend=:bottomright)
    plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    # savefig("cost_userpair.png")
    # savefig("cost_userpair.pdf")

    plot(x, P0, linewidth=2, label=L"$P_0$", legend= :topright)
    plot!(x, P1, linewidth=2, label=L"$P_1$")
    plot!(x, P2, linewidth=2, label=L"$P_2$")
    plot!(x, P3, linewidth=2, label=L"$P_3$")
    # xaxis!(L"$\textrm{Number of End User Pairs}$")
    # yaxis!(L"$\textrm{Average Number of Paths Used Per User Pair}$")
    # savefig("path_userpair.png")
    # savefig("path_userpair.pdf")
end


"""
Plot the performance statistics of greedy-multi-path with respect to edge percolation
rate (The probability that a given edge is removed)
"""
function plot_with_percolations(perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)
    # number of end-user pairs
    num_pairs = 3

    # Network to be percolated.
    size = 10
    net = GridNetwork(size, size)

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

    # # Possibly redundent here?
    # loss_arr = replace(loss_arr, nothing=>NaN)
    # z_arr = replace(z_arr, nothing=>NaN)

    # Extract data from path: PX is the rate of using X paths
    P0 = [path_data[i][1]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P1 = [path_data[i][2]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P2 = [path_data[i][3]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
    P3 = [path_data[i][4]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]

    # Save data to csv
    # file = "percolations.csv"
    # writedlm(file,  ["Average number of paths used",
    #                 path_data, "Efficiency", loss_arr,
    #                 "Efficiency Error", loss_error,
    #                 "Z-dephasing", z_arr,
    #                 "Z Error", z_error], ',')

    # Plot
    plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
    legend=:bottomright)
    plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")
    xaxis!(L"$\textrm{Probability of Edge Removal}$")
    # savefig("cost_percolation.pdf")
    # savefig("cost_percolation.png")

    plot(x, P0, linewidth=2, label=L"$P_0$", legend= :topright)
    plot!(x, P1, linewidth=2, label=L"$P_1$")
    plot!(x, P2, linewidth=2, label=L"$P_2$")
    plot!(x, P3, linewidth=2, label=L"$P_3$")
    xaxis!(L"$\textrm{Probability of Edge Removal}$")
    # savefig("path_percolation.pdf")
    # savefig("path_percolation.png")
end


"""
Plot the performance statistics of greedy-multi-path with respect to the timedepth
of the graph
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

    # Collect data for horizontal lines:
    # single-user-single-path
    susp = analytic_single_user_single_path_cost(grid_size)
    e_susp = ones(length(1:max_depth)) * susp[1]
    f_susp = ones(length(1:max_depth)) * susp[2]
    # single-user-multi-path
    println("Collecting data for sump")
    sump = numerical_single_user_multi_path_cost(grid_size)
    e_sump = ones(length(1:max_depth)) * sump[1]
    f_sump = ones(length(1:max_depth)) * sump[2]

    # Get values for x axis
    x = collect(1:max_depth)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Extract error data
    loss_error = collect(map(x->x["loss"], err_data))
    z_error = collect(map(x->x["Z"], err_data))

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

    # Plot horizontal lines
    plot!(x, e_susp, linestyle=:dash, color=:red, label=L"$\textrm{Average path } \eta$")
    plot!(x, f_susp, linestyle=:dash, color=:green, label=L"$\textrm{Average path } F$")
    plot!(x, e_sump, linestyle=:dot, color=:red, linewidth=2, label=L"$\textrm{Asymptotic single-pair } \eta$")
    plot!(x, f_sump, linestyle=:dot, color=:green, linewidth=2, label=L"$\textrm{Asymptotic single-pair } F$")

    xaxis!(L"$\textrm{Time Depth of Temporal Meta-Graph}$")
    savefig("temporal.pdf")
    savefig("temporal.png")
end


"""
Plot performance statistics of greedy-multi-path with respect to grid size of the network
"""
function plot_with_gridsize(num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
    @assert min_size < max_size
    @assert num_pairs*2 <= min_size^2 "Graph size too small for num_pairs"

    perf_data = []
    collision_data = []
    path_data = []

    size_list = collect(min_size:1:max_size)
    for i in size_list
        println("Collecting for gridsize: $i")
        # Generate ixi graph:
        net = GridNetwork(i, i)

        # Collect performance statistics
        performance, collisions, ave_paths_used = net_performance(net, num_trials, num_pairs)
        collision_rate = collisions/(num_trials*num_pairs)
        push!(collision_data, collision_rate)
        push!(perf_data, performance)
        push!(path_data, ave_paths_used)
    end

    # Get values for x axis
    x = collect(min_size:1:max_size)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Save data to csv
    file = "gridsize.csv"
    writedlm(file,  ["Average number of paths used",
                    path_data, "Efficiency", loss_arr,
                    "Z-dephasing", z_arr], ',')

    # Plot
    plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P$",
    legend=:bottomright)
    plot!(x, loss_arr, linewidth=2, label=L"$\eta$")
    plot!(x, z_arr, linewidth=2, label=L"$F$")
    xaxis!(L"$\textrm{Grid Size}$")
    savefig("cost_gridsize.png")
    savefig("cost_gridsize.pdf")

    plot(x, path_data, linewidth=2, legend=false)
    xaxis!(L"$\textrm{Grid Size}$")
    yaxis!(L"$\textrm{Average Number of Paths Used Per User Pair}$")
    savefig("path_gridsize.png")
    savefig("path_gridsize.pdf")
end

"""
For a given grid size, this function calculates the average manhattan distance
between two random points, then (assuming the channels have unit cost) returns
the average efficiency and fidelity
"""
function analytic_single_user_single_path_cost(gridsize::Int64)
    man_dist = 2/3*(gridsize + 1)
    e = dB_to_P(man_dist)
    f = dB_to_Z(man_dist)
    return(e, f)
end


"""
For a given grid size, this function runs the greedy_multi_path routing algorithm
on randomly placed end-user pairs.
"""
function numerical_single_user_multi_path_cost(gridsize::Int64)
    N = 10000
    G = GridNetwork(gridsize, gridsize)
    pfmnce_data, dummy = net_performance(G, N, 1)
    return pfmnce_data["loss"], pfmnce_data["Z"]
end


"""
Plot the performance statistics of greedy_multi_path for 1 random end-user pair
over a range of graph sizes and for different numbers of max_path (1,2,3) (ie. the
maximum number of paths that can be purified by a given end-user pair.)
"""
function plot_maxpaths_with_gridsize(num_trials::Int64, min_size::Int64, max_size::Int64)
    @assert min_size < max_size
    @assert num_pairs*2 <= min_size^2 "Graph size too small for num_pairs"

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
            performance, dummy, dummier = net_performance(net, num_trials, 1, max_paths=j)
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

    # Plot
    plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", color = :red, legend=:right)
    plot!(x, z_arr1, linewidth=2, label=L"$F_1$", linestyle=:dash, color =:red)
    plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", color =:blue)
    plot!(x, z_arr2, linewidth=2, label=L"$F_2$", linestyle=:dash, color =:blue)
    plot!(x, loss_arr3, linewidth=2, label=L"$\eta_3$", color =:green)
    plot!(x, z_arr3, linewidth=2, label=L"$F_3$", linestyle=:dash, color =:green)

    xaxis!(L"$\textrm{Grid Size}$")
    savefig("cost_maxpaths.png")
    savefig("cost_maxpaths.pdf")
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
# plot_with_userpairs(40, 100000)
# plot_with_userpairs(20, 1000)

# Usage : (perc_range::Tuple{Float64, Float64, Float64}, num_trials::Int64)
# plot_with_percolations((0.0, 0.01, 0.7), 100000)
# plot_with_percolations((0.0, 0.1, 0.7), 10000)

# Usage : (num_trials::Int64, max_depth::Int64)
# plot_with_timedepth(100, 30)

# Usage : (num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
# plot_with_gridsize(100, 40, 10, 150)

# Usage : (num_trials::Int64, num_pairs::Int64, min_size::Int64, max_size::Int64)
# plot_maxpaths_with_gridsize(10000, 10, 30)

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
