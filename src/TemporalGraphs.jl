mutable struct TemporalGraph
    #graph::SimpleWeightedDiGraph
    graph::Dict
    nv::Int64
    steps::Int64
    # Visual coordinates
    locs_x::Vector{Float64}
    locs_y::Vector{Float64}

    TemporalGraph() = new(Dict{String,SimpleWeightedDiGraph}(), 0, 1, Vector{Float64}(), Vector{Float64}())
end

function TemporalGraph(network::QNetwork, steps::Int64)::TemporalGraph
    temp_graph = TemporalGraph()
    temp_graph.nv = length(network.nodes)
    temp_graph.steps = steps

    for cost_key in keys(zero_costvector())
        temp_graph.graph[cost_key] = SimpleWeightedDiGraph()

        for t in 1:steps
            # Vertices
            add_vertices!(temp_graph.graph[cost_key], temp_graph.nv)

            # Channels
            for channel in network.channels
                if channel.active == true
                    src = findfirst(x -> x == channel.src, network.nodes) + (t-1)*temp_graph.nv
                    dest = findfirst(x -> x == channel.dest, network.nodes) + (t-1)*temp_graph.nv
                    weight = channel.costs[cost_key]
                    add_edge!(temp_graph.graph[cost_key], src, dest, weight)
                    add_edge!(temp_graph.graph[cost_key], dest, src, weight)
                end
            end
        end

        # Memory channels
        for t in 1:(steps-1)
            for node in 1:temp_graph.nv
                src = node + (t-1)*temp_graph.nv
                dest = src + temp_graph.nv
                add_edge!(temp_graph.graph[cost_key], src, dest, 1.0)
            end
        end

        # Coords
        offsetX = 0.1
        offsetY = 0.2

        for t in 1:steps
            for node in network.nodes
                push!(temp_graph.locs_x, node.location.x + (t-1) * offsetX)
                push!(temp_graph.locs_y, node.location.y + (t-1) * offsetY)
            end
        end
    end

    return temp_graph
    # fix up edge weights
end


# TODO: This is ok, but it shouldn't take a QNetwork as an object. Should take
# Whatever the temporal graph structure is

function add_async_nodes!(tempnet::QuNet.TemporalGraph)
    # Minimal weight constant
    ϵ = 1e-9
    N = tempnet.nv
    steps = tempnet.steps
    for costkey in keys(zero_costvector())
        graph = tempnet.graph[costkey]
        @assert nv(graph) == N * steps "Graph too small for number of steps given:
        nv(graph) == $(nv(graph)) != N*steps == $(N*steps)"
        # Add the asynchronus nodes
        add_vertices!(graph, N)
        # Keep track of indices of async nodes
        async_idxs = collect(N*steps + 1: N*steps + N)
        for t in 1:steps
            # Connect each temporal node to its async counterpart
            # Use minimal time dependent weight to prioritise top layers when routing
            for i in 1:N
                add_edge!(graph, i+N*(t-1), async_idxs[i], ϵ*t)
                add_edge!(graph, async_idxs[i], i+N*(t-1), ϵ*t)
            end
        end
    end
end


function remove_async_nodes!(tempnet::QuNet.TemporalGraph)
    N = tempnet.nv
    steps = tempnet.steps
    for costkey in keys(zero_costvector())
        graph = tempnet.graph[costkey]
        @assert nv(graph) == N * steps + N
        # Remove nodes with decreasing id so iteration works
        kill_list = reverse(collect(N*steps+1:N*steps+N))
        for i in kill_list
            rem_vertex!(graph, i)
        end
    end
end


function gplot(temp_graph::TemporalGraph)
    gplot(temp_graph.graph["loss"], temp_graph.locs_x, temp_graph.locs_y, arrowlengthfrac=0.04)
end
