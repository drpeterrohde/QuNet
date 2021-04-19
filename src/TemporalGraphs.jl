mutable struct TemporalGraph <: QObject
    #graph::SimpleWeightedDiGraph
    graph::Dict
    nv::Int64
    steps::Int64
    # Visual coordinates
    locs_x::Vector{Float64}
    locs_y::Vector{Float64}
    has_async_nodes::Bool

    TemporalGraph() = new(Dict{String,SimpleWeightedDiGraph}(), 0, 1, Vector{Float64}(), Vector{Float64}(), false)
end

function TemporalGraph(network::QNetwork, steps::Int64; memory_prob::Float64=1.0,
    memory_costs::Dict=Dict())::TemporalGraph
    temp_graph = TemporalGraph()
    temp_graph.nv = length(network.nodes)
    temp_graph.steps = steps
    temp_graph.has_async_nodes = false

    # Make a copy of the network so we don't change QNetwork structure.
    netcopy = deepcopy(network)

    if memory_prob != 1.0
        @assert 0 <= memory_prob <= 1
        # Iterate through nodes and randomly reassign memories according to memory_prob
        # TODO: BAD PRACTICE. Don't manipulate QNetwork data.
        for node in netcopy.nodes
            if rand(Float64) <= memory_prob
                node.has_memory = true
            else
                node.has_memory = false
            end
        end
    end

    # Keep tabs on which nodes have memories and what the the associated cost are
    node_memories = Dict()
    node_memory_costs = Dict()
    for node in netcopy.nodes
        node_memories[node.id] = node.has_memory
        node_memory_costs[node.id] = node.memory_costs
    end

    for cost_key in keys(zero_costvector())
        temp_graph.graph[cost_key] = SimpleWeightedDiGraph()

        for t in 1:steps
            # Vertices
            add_vertices!(temp_graph.graph[cost_key], temp_graph.nv)

            # Channels
            for channel in netcopy.channels
                if channel.active == true
                    src = findfirst(x -> x == channel.src, netcopy.nodes) + (t-1)*temp_graph.nv
                    dest = findfirst(x -> x == channel.dest, netcopy.nodes) + (t-1)*temp_graph.nv
                    weight = channel.costs[cost_key]
                    add_edge!(temp_graph.graph[cost_key], src, dest, weight)
                    add_edge!(temp_graph.graph[cost_key], dest, src, weight)
                end
            end
        end

        # Memory channels
        for t in 1:(steps-1)
            for node in 1:temp_graph.nv
                # Add temporal link if memory exists
                if node_memories[node] == true
                    # WARNING: Memory costs aren't dependent on the timestep size.
                    # If the user specified a memory cost, use that.
                    if length(memory_costs) != 0
                        cost = memory_costs[cost_key]
                    # Otherwise pull it from the node attribute
                    else
                        cv = node_memory_costs[node]
                        cost = cv[cost_key]
                    end
                    # If the cost is zero, set it to epsilon so SimpleWeightedGraphs
                    # add it to the sparse adj. matrix.
                    if cost == 0
                        cost = eps(Float64)
                    end

                    src = node + (t-1)*temp_graph.nv
                    dest = src + temp_graph.nv
                    add_edge!(temp_graph.graph[cost_key], src, dest, cost)
                end
            end
        end

        # Coords

        # Offset factor for temporal nodes
        offsetX = 0.1
        offsetY = 0.2

        for t in 1:steps
            for node in netcopy.nodes
                push!(temp_graph.locs_x, node.location.x + (t-1) * offsetX)
                push!(temp_graph.locs_y, node.location.y + (t-1) * offsetY)
            end
        end
    end

    return temp_graph
end

"""
Add asynchronus nodes to a Temporal Network.

This function adds tempnet.nv nodes to the graph. If a given node is source,
outgoing asynchronus edges are added to the node that connects it to its temporal
counterparts. This is done with incremental timeweights ϵ so that earlier times
are prioritized.

Likewise if a node is a dest, incoming asynchronus edges are added with incremental
weights ϵ.
"""
function add_async_nodes!(tempnet::QuNet.TemporalGraph, endusers::Vector{Tuple{Int64, Int64}};
    ϵ=1)

    # No double dipping!
    if tempnet.has_async_nodes == true
        @warn("Redundent use of add_async_nodes -- T.has_async_nodes == true
        Returning an unmodified TemporalGraph")
        return tempnet
    end

    N = tempnet.nv
    steps = tempnet.steps
    # index offset for asynchronus nodes
    async_offset = N*steps

    # Keep track of asynchronus src and dst nodes
    src_nodes = []
    dst_nodes = []
    for userpair in endusers
        src = userpair[1]
        dst = userpair[2]
        if src > async_offset
            push!(src_nodes, src)
        end
        if dst > async_offset
            push!(dst_nodes, dst)
        end
    end

    for costkey in keys(zero_costvector())
        graph = tempnet.graph[costkey]
        # Add the asynchronus nodes
        add_vertices!(graph, N)

        # Connect async nodes to temporal counterparts:
        for async in (1 + async_offset):(N + async_offset)
            # If node is a src, make asynchronus channels outgoing
            if async in src_nodes
                for t in 1:steps
                    # Connect each temporal node to its async counterpart
                    # Use time_dependent weight to prioritise top layers when routing
                    #add_edge(src, dst)
                    add_edge!(graph, async, async%async_offset + N*(t-1), ϵ*t)
                end
            # If node is a dst, make asynchronus channels incoming
            elseif async in dst_nodes
                for t in 1:steps
                    add_edge!(graph, async%async_offset + N*(t-1), async, ϵ*t)
                end
            end
        end
    end
    tempnet.has_async_nodes = true
end

"""
Remove all asynchronus nodes of a TemporalGraph.

i.e. those put in place by add_async_nodes!
"""
function remove_async_nodes!(tempnet::QuNet.TemporalGraph)

    # No double dipping!
    if tempnet.has_async_nodes == false
        @warn("Redundent use of remove_async_nodes -- T.has_async_nodes == false
         Returning an unmodified TemporalGraph")
        return tempnet
    end

    offset = tempnet.nv * tempnet.steps
    for costkey in keys(zero_costvector())
        graph = tempnet.graph[costkey]
        # Assertion is no longer valid since not all async nodes from offset+1 to offset+N are generated
        # @assert nv(graph) == N * steps + N
        # Remove nodes with decreasing id so iteration works
        kill_list = reverse(collect((offset + 1) : (offset + tempnet.nv)))
        for i in kill_list
            rem_vertex!(graph, i)
        end
    end
    tempnet.has_async_nodes = false
end

"""
TODO: DOESN'T WORK

Remove the asynchronus edges of a TemporalGraph, excluding those connecting
specified layers
"""
# function remove_async_edges!(tempnet::QuNet.TemporalGraph, exclude_layers...)
#
#     @assert(all(0 < i <= tempnet.steps for i in exclude_layers))
#     # offset index for asynchronus nodes
#     offset = tempnet.nv * tempnet.steps
#
#     for costkey in keys(zero_costvector())
#         graph = tempnet.graph[costkey]
#         for async_node in offset + 1 : offset + tempnet.nv
#             nlist = all_neighbors(graph, async_node)
#             # remove nodes in nlist that are in the excluded layers
#             # BUG, this filters nodes, not edge layers.
#             filter!(x -> !((x-1) ÷ tempnet.nv in exclude_layers), nlist)
#             for node in nlist
#                 # Remove in both directions just in case
#                 rem_edge!(graph, async_node, node)
#                 rem_edge!(graph, node, async_node)
#             end
#         end
#     end
# end


"""
Convert temporal nodes into asynchronus nodes
If the node is already asynchronus, it is returned
Throws an exception if the node is out of bounds
"""
function temp_to_async(nv::Int, steps::Int, node::Int)
    offset = nv * steps
    if node <= 0 || node > offset + nv
        error("Node index out of bounds")
    elseif node > offset
        return node
    end
    mod = node % nv
    if mod == 0
        mod = nv
    end
    return mod + offset
end


"""
Get the temporal depth of a node from its index. If asynchronus, return -1
Throws an exception if the node is out of bounds.
"""
function node_timedepth(nv::Int, steps::Int, node::Int)
    offset = nv * steps
    if node <= 0 || node > offset + nv
        error("Node index out of bounds")
    elseif node > offset
        return -1
    end
    if node % nv == 0
         return (node-1) ÷ nv + 1
    end
    return (node ÷ nv) + 1
end


"""
Get the relative index of a node from its original index.
ie. for a graph with nv = 10, steps = 3, then node 14
is the same relative to node 4. Another way to think about this
is that it gets the index of the corresponding node in the top layer.
"""
function relative_index(nv::Int, steps::Int, node::Int)
    offset = nv * steps
    if node <= 0 || node > offset + nv
        error("Node index out of bounds")
    end
    mod = node % nv
    if mod == 0
        return nv
    end
    return mod
end


"""
For a given node at time T in a TemporalGraph, this function fixes its asynchronus
counterpart with respect to T This is done by removing all edges of the asynchronus node
except for the one connecting at time T.
"""
function fix_async_nodes_in_time!(tempnet::QuNet.TemporalGraph, node_list::Vector{Int})

    if tempnet.has_async_nodes == false
        return tempnet
    end

    offset = tempnet.steps * tempnet.nv
    # Check that nodes are valid non-temporal indices
    @assert(all(0 < i <= offset for i in node_list))

    for costkey in keys(zero_costvector())
        graph = tempnet.graph[costkey]
        for node in node_list
            # Relative_index of node
            rel = relative_index(tempnet.nv, tempnet.steps, node)
            # Get the timedepth of the node
            depth = node_timedepth(tempnet.nv, tempnet.steps, node)
            # Get the asynchronus counterpart of node
            async = temp_to_async(tempnet.nv, tempnet.steps, node)

            for i in 1:tempnet.steps
                if i != depth
                    hard_rem_edge!(graph, rel + (i-1)*tempnet.nv, async)
                end
            end
        end
    end
end


function gplot(temp_graph::TemporalGraph)
    gplot(temp_graph.graph["loss"], temp_graph.locs_x, temp_graph.locs_y, arrowlengthfrac=0.04)
end
