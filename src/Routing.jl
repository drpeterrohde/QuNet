weights = SimpleWeightedGraphs.weights

"""
Find the shortest path between two nodes of an AbstractGraph by using the
\'a star\' method. Returns a vector of AbstractEdge. If no path is found,
returns an empty vector.
"""
function shortest_path(graph::AbstractGraph, src::Int64, dst::Int64)
    path = a_star(SimpleDiGraph(weights(graph)), src, dst, weights(graph))
    return path
end
# Change SimpleDiGraph to SimpleWeightedDiGraph

"""
Finds the total weight/length of a path for a given AbstractGraph.

!!! warning
    For whatever reason, SimpleWeightedDiGraph indexes weights with [dest, src].
    Keep in mind this path_length will likely not work if you pass in anything
    but a SimpleWeightedDiGraph.
"""
function path_length(graph::AbstractGraph, path)::Float64
    dist = 0.0
    for edge in path
        # SimpleWeightedDiGraph indexes by [src, dst]. Be careful here!
        dist += graph.weights[edge.dst, edge.src]
    end
    return dist
end


"""
Removes the shortest path between two nodes of an abstract graph and returns
the cost. If no path exists, return nothing

!!! warning
    As pointed out in shortest_path, SimpleWeightedDiGraph indexes weights with
    [dest, src]. Keep in mind this method will likely not work if you pass in
    anything but a SimpleWeightedDiGraph
"""
function remove_shortest_path!(graph::AbstractGraph, src::Int64, dst::Int64;
    istemp = false)

    # Get shortest path. If no path exists, return nothing
    path = shortest_path(graph, src, dst)
    if length(path) == 0
        return nothing
    end

    # Else get the cost of the path
    cost = path_length(graph, path)

    # If path is in TemporalGraph, pop edge list so asynchronus links aren't removed
    if istemp == true
        popfirst!(path)
        pop!(path)
    end

    # Hard remove the path from the graph
    for edge in path
        status = hard_rem_edge!(graph, edge.src, edge.dst)
        if status == false
            error("Failed to remove edge in path")
        end
    end
    return cost
end

"""
Removes the shortest path between two nodes of a QNetwork *with respect to a
given cost* and returns the cost vector for the path.
"""
function remove_shortest_path!(network::QNetwork, cost::String, src::Int64, dst::Int64)
    @assert cost in keys(zero_costvector()) "Invalid cost"

    path_costs = Dict{String, Float64}()
    for cost_type in keys(zero_costvector())
        cost = remove_shortest_path!(network.graph[cost_type], src, dst)
        # If cost is nothing, no path exists. Return nothing
        if cost == nothing
            return nothing
        end
        path_costs[cost_type] = cost
    end
    return path_costs
end

"""
Remove the shortest_path of a TemporalGraph, making sure not to remove the edge
between the asynchronous node and its temporal counterpart. When specifying
src and dst, specify them as you would if the graph were non-temporal. E.G. if
you have a 1x2 network with 2 timesteps and you wanted to find the best path
between the two nodes, you would specify src:1, dst:2
"""
function remove_shortest_path!(tempnet::QuNet.TemporalGraph, cost::String,
    src::Int64, dst::Int64)
    @assert cost in keys(zero_costvector()) "Invalid cost"

    # Check that src and dst are nodes within range(1, size-of-static-graph)
    if (src > tempnet.nv && dst > tempnet.nv)
    # if (src <= tempnet.nv * tempnet.steps || dst <= tempnet.nv * tempnet.steps)
        @assert 1==0 "(src::$src) and (dst::$dst) nodes must be asynchronous"
    end

    # Reindex src and dst so that they point to their asynchronus counterparts
    src += tempnet.nv * tempnet.steps
    dst += tempnet.nv * tempnet.steps

    path_costs = Dict{String, Float64}()
    for cost_type in keys(zero_costvector())
        cost = remove_shortest_path!(tempnet.graph[cost_type], src, dst, istemp=true)
        # If cost is nothing, no path exists. Return nothing
        if cost == nothing
            return nothing
        end
        path_costs[cost_type] = cost
    end
    return path_costs
end

"""
greedy_multi_path! is an entanglement routing strategy for a quantum network
with n end user pairs.

1. Each user pair has an associated "bundle" of paths that starts out empty.
For each user pair, find the shortest path between them, and add its cost to the
bundle. If no path exists, add "nothing" to the bundle.

2. When all the bundles are filled up to the maximum number "maxpaths", use an
entanglement purification method between the path costs. Add the resulting cost
vector to the array pur_paths. If no paths exist for a given bundle, increment
the collision count by one, and add "nothing" to pur_paths

3. Return the array of purified cost vectors and the collision count.
"""
function greedy_multi_path!(network::QNetwork, purification_method,
    users, maxpaths::Int64=3)

    # List of path costs for each userpair
    path_costs = [Vector{Dict{Any,Any}}() for i in 1:length(users)]
    # Number of paths used for a given userpair. This will be averaged later
    num_paths_used = []

    for i in 1:maxpaths

        for (userid, user) in enumerate(users)
            src = user[1]
            dst = user[2]

            # Remove the shortest path (In terms of Z - dephasing) and get its associated cost vector.
            pathcv = remove_shortest_path!(network, "Z", src, dst)
            # If pathcv is nothing, no path was found.
            if pathcv == nothing
                break
            else
                push!(path_costs[userid], pathcv)
            end
        end
    end

    # Purify each path set, checking for collisions
    collisions = 0
    # Vector{Dict{Any, Any}}()
    pur_paths = []

    for userpaths in path_costs
        push!(num_paths_used, length(userpaths))
        # If length(userpaths) == 0, no paths were found. No purification possible.
        if length(userpaths) == 0
            collisions += 1
            push!(pur_paths, nothing)
        # Otherwise, purify.
        else
            purcost::Dict{Any, Any} = purification_method(userpaths)
            # Convert purcost from decibels to metric form
            purcost = convert_costs(purcost)
            push!(pur_paths, purcost)
        end
    end

    # Find the average number of paths used:
    ave_paths_used = mean(num_paths_used)

    return pur_paths, collisions, ave_paths_used
end


function greedy_multi_path!(tempnet::QuNet.TemporalGraph, purification_method,
    users, maxpaths::Int64=3)

    # List of path costs for each userpair, where top-level index is userpair.
    # v = Vector{Dict{Any, Any}}()
    # path_costs = fill(v, length(users))
    path_costs = [Vector{Dict{Any,Any}}() for i in 1:length(users)]

    for i in 1:maxpaths

        for (userid, user) in enumerate(users)
            src = user[1]
            dst = user[2]

            # Remove the shortest path (In terms of dephasing)
            pathcv = remove_shortest_path!(tempnet, "Z", src, dst)
            # If pathcv is nothing, no path was found.
            if pathcv == nothing
                break
            else
                push!(path_costs[userid], pathcv)
            end
        end
    end

    # Purify each path set, checking for collisions
    collisions = 0
    # Vector{Dict{Any, Any}}()
    pur_paths = []

    for userpaths in path_costs
        # If length(userpaths) == 0, no paths were found. No purification possible.
        if length(userpaths) == 0
            collisions += 1
            push!(pur_paths, nothing)
        # Otherwise, purify.
        else
            purcost::Dict{Any, Any} = purification_method(userpaths)
            # Convert purcost from decibels to metric form
            purcost = convert_costs(purcost)
            push!(pur_paths, purcost)
        end
    end
    return pur_paths, collisions
end


"""
greedy_multi_pathset! is an entanglement routing strategy for a quantum network
with n end user pairs. It is identical to greedy_multi_path!, the only difference
being that this function returns the set of userpaths. (i.e. the list of paths selected
for each end-user pair) Refer to greedy_multi_path! documentation for more info.
"""
function greedy_multi_pathset!(tempnet::QuNet.TemporalGraph, purification_method,
    users, maxpaths::Int64=3)

    path_set = [Vector() for i in 1:length(users)]

    for i in 1:maxpaths

        for (userid, user) in enumerate(users)
            src = user[1]
            dst = user[2]

            # Get the shortest path (In terms of dephasing)
            path = shortest_path(tempnet.graph["Z"], src, dst)

            # Hard remove the path from the graph
            for edge in path
                status = hard_rem_edge!(tempnet.graph["Z"], edge.src, edge.dst)
                if status == false
                    error("Failed to remove edge in path")
                end
            end

            # If pathcv is nothing, no path was found.
            if path == nothing
                break
            else
                push!(path_set[userid], path)
            end
        end
    end
    return path_set
end
