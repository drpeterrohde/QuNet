"""
Scratch file for testing with Juno Debugger
"""

using QuNet
using LightGraphs
using SimpleWeightedGraphs

"""
Two different temporal plots, one with memory and one without. While varying the
number of end-users, we compare the ratio of the depths of the graphs
"""
function temporal_bandwidth_plot(num_trials::Int64, max_pairs::Int64)

    grid_size = 3
    time_depth = 3

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
            # Add async nodes
            QuNet.add_async_nodes!(T_mem, mem_user_pairs, ϵ=100)
            QuNet.add_async_nodes!(T, user_pairs, ϵ=100)
            # Get pathset data
            pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem, QuNet.purify, mem_user_pairs)
            pathset, dum1, dum2 = QuNet.greedy_multi_path!(T, QuNet.purify, user_pairs)
            # Pathset is an array of vectors containing edges describing paths between end-user pairs
            # Objective: find the largest timedepth used in the pathsets

            # DEBUG
            if i = 50 && j == 1
                println("pathset_mem = $pathset_mem")
                println("pathset = $pathset")

            """
            Find the maximum timedepth reached by a given pathset
            """
            function max_timedepth(pathset, T)
                max_depth = 1
                for bundle in pathset
                    for path in bundle
                        edge = last(path)
                        node = edge.dst
                        # Check if node is temporal. If it is, use src instead
                        if node > T.nv * T.steps
                            node = edge.src
                        end
                        # use node - 1 here because if node % T.nv == 0, depth is off by one
                        depth = (node - 1) ÷ T.nv
                        if depth > max_depth
                            max_depth = depth
                        end
                    end
                end
                return max_depth
            end

            max_depth_mem = max_timedepth(pathset_mem, T)
            max_depth = max_timedepth(pathset, T)
            # Get the ratio of these two quantities. Add it to data array
            push!(raw_data, max_depth_mem / max_depth)
        end
        # Average the raw data, add it to plot data:
        push!(plot_data, mean(raw_data))
        # Get standard error
        push!(error_data, std(raw_data)/sqrt(num_trials - 1))
    end
end

temporal_bandwidth_plot(5, 1)
