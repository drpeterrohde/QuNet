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
function make_user_pairs(net::QNetwork, num_pairs::Int)::Vector{Tuple{Int64, Int64}}
    num_nodes = length(net.nodes)
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
Generate a list of end-users for a TemporalGraph.
src_layer and dst_layer specify the temporal locations of the source and dst nodes
respectively. The default value for these is -1, which indicates the end-users should
be asynchronus.
"""
function make_user_pairs(net::QuNet.TemporalGraph, num_pairs::Int;
    src_layer::Int64=-1, dst_layer::Int64=-1)::Vector{Tuple{Int64, Int64}}

    num_nodes = net.nv
    @assert num_nodes >= num_pairs*2 "Graph space too small for number of pairs"
    @assert dst_layer <= net.steps "dst_layer must be between 1 and $(net.steps) -- or -1 for async nodes"

    rand_space = Array(collect(1:num_nodes))
    pairs = Vector{Tuple}()
    i = 0
    while i < num_pairs
        # Random source
        idx = rand(1:length(rand_space))
        u = rand_space[idx]
        deleteat!(rand_space, idx)

        # Random dest
        idx = rand(1:length(rand_space))
        v = rand_space[idx]
        deleteat!(rand_space, idx)

        # Update u and v to point to the specified source and dest layers
        # If src_layer == -1, index to async_nodes
        if src_layer == -1
            u += num_nodes * net.steps
        elseif src_layer > 0
            u += (src_layer - 1) * num_nodes
        else
            error("Invalid src_layer. Choose from {1, ..., T.steps} or -1 for asynchronus nodes")
        end

        if dst_layer == -1
            v += num_nodes * net.steps
        elseif dst_layer > 0
            v += (dst_layer - 1) * num_nodes
        else
            error("Invalid dst_layer. Choose from {1, ..., T.steps} or -1 for asynchronus nodes")
        end

        chosen_pair = (u, v)
        push!(pairs, chosen_pair)
        i += 1
    end
    return pairs
end

"""
Given a tally for the number of paths used by each end-user in a greedy_protocol:
(i.e. [3,4,2,1] meaning 3 end-users used no paths, 4, end-users used 1 path, etc.)
This function finds the average number of paths used in the protocol.
"""
function ave_paths_used(pathuse_count::Vector{Float64})
    ave_pathuse = 0.0
    len = length(pathuse_count)
    for i in 1:len
        ave_pathuse += (i-1) * pathuse_count[i]
    end
    ave_pathuse = ave_pathuse / sum(pathuse_count)
    return ave_pathuse
end


"""
Takes a network as input and return greedy_multi_path! performance statistics for some number of
random user pairs. Ensure graph is refreshed before starting.
"""
function net_performance(network::Union{QNetwork, QuNet.TemporalGraph},
    num_trials::Int64, num_pairs::Int64; max_paths=3, src_layer::Int64=-1,
    dst_layer::Int64=-1, edge_perc_rate=0.0)

    # Sample of average routing costs between end-users
    ave_cost_data = []
    # Sample of path usage statistics for the algorithm
    pathcount_data = []

    for i in 1:num_trials
        net = deepcopy(network)

        # Generate random communication pairs
        if typeof(network) == TemporalGraph
            user_pairs = make_user_pairs(network, num_pairs, src_layer=src_layer, dst_layer=dst_layer)
            # Add asynchronus nodes to the network copy
            add_async_nodes!(net, user_pairs)
        else
            user_pairs = make_user_pairs(network, num_pairs)
        end

        # Percolate edges
        # WARNING: Edge percolation will not be consistant between temporal layers
        # if typeof(net) = QuNet.TemporalGraph
        if edge_perc_rate != 0.0
            @assert 0 <= edge_perc_rate <= 1.0 "edge_perc_rate out of bounds"
            net = QuNet.percolate_edges(net, edge_perc_rate)
            refresh_graph!(net)
        end

        # Get data from greedy_multi_path
        dummy, routing_costs, pathuse_count = QuNet.greedy_multi_path!(net, purify, user_pairs, max_paths)

        # Filter out entries where no paths were found and costs are not well defined
        filter!(x->x!=nothing, routing_costs)

        # If the mean is well defined, average the routing costs and push to ave_cost_data
        if length(routing_costs) > 0
            # Average the data
            ave = dict_average(routing_costs)
            push!(ave_cost_data, ave)
        end
        push!(pathcount_data, pathuse_count)
    end

    # Find the mean and standard error of ave_cost_data. Call this the performance
    performance = dict_average(ave_cost_data)
    performance_err = dict_err(ave_cost_data)

    # Find the mean and standard error of the path usage statistics:

    # Usage:
        # Each entry in pathcount_data is a vector of Ints of length (max_paths + 1)
        # An example entry is [3, 4, 3, 1]
        # Where 3 end-users found 0 paths, 4 end-users found 1 path, etc.
        # Given a collection of path statistics, ie. [[0, 1, 2, 1], [0, 0, 3, 0], [0, 1, 2, 1]]
        # we want to return vectors of average path usage with associated error:
        # ie. [0, 0.666, 2.333, 0.666] for means
    ave_pathcounts = [0.0 for i in 0:max_paths]
    ave_pathcounts_err = [0.0 for i in 0:max_paths]

    for i in 1:max_paths+1
        data = [pathcount_data[j][i] for j in 1:num_trials]
        ave_pathcounts[i] = mean(data)
        ave_pathcounts_err[i] = std(data)/(sqrt(length(data)))
    end

    return performance, performance_err, ave_pathcounts, ave_pathcounts_err
end
