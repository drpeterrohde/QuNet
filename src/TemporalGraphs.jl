mutable struct TemporalGraph
    graph::SimpleWeightedDiGraph
    nv::Int64
    steps::Int64
    locs_x::Vector{Float64}
    locs_y::Vector{Float64}

    TemporalGraph() = new(SimpleWeightedDiGraph(), 0, 1, Vector{Float64}(), Vector{Float64}())
end

function TemporalGraph(network::QNetwork, steps::Int64)::TemporalGraph
    temp_graph = TemporalGraph()
    temp_graph.nv = length(network.nodes)
    temp_graph.steps = steps

    for t in 1:steps
        add_vertices!(temp_graph.graph, temp_graph.nv)

        for channel in network.channels
            src = findfirst(x -> x == channel.src, network.nodes) + (t-1)*temp_graph.nv
            dest = findfirst(x -> x == channel.dest, network.nodes) + (t-1)*temp_graph.nv
            add_edge!(temp_graph.graph, src, dest, 1.0)
        end
    end

    # Memory channels
    for t in 1:(steps-1)
        for node in 1:temp_graph.nv
            src = node + (t-1)*temp_graph.nv
            dest = src + temp_graph.nv
            add_edge!(temp_graph.graph, src, dest, 1.0)
        end
    end

    # Coords
    offsetX = 1.5
    offsetY = 15

    for t in 1:steps
        for node in network.nodes
            push!(temp_graph.locs_x, node.location.x + (t-1) * offsetX)
            push!(temp_graph.locs_y, node.location.y + (t-1) * offsetY)
        end
    end

    return temp_graph

    # fix up edge weights
end

function gplot(temp_graph::TemporalGraph)
    gplot(temp_graph.graph, temp_graph.locs_x, temp_graph.locs_y, arrowlengthfrac=0.04)
end