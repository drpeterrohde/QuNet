# Taken from MultiPathDemo.jl
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
Takes a network as input and return greedy_multi_path! performance statistics for some number of
random user pairs.
"""
function net_performance(network::QNetwork, num_trials::Int64, num_pairs::Int64,
    with_err::Bool=false; max_paths=3)

    total_collisions = 0
    pfmnce_data = []
    path_data = []

    for i in 1:num_trials
        net = deepcopy(network)

        # No need to refresh graph here. GridNetwork is already ready to go
        #refresh_graph!(net)

        # Generate random communication pairs
        user_pairs = make_user_pairs(network, num_pairs)
        # NOTE Added max_paths here. Check me first if something goes wrong.
        net_data, collisions, ave_paths_used = QuNet.greedy_multi_path!(net, purify, user_pairs, max_paths)
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
