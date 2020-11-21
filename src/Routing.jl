function shortest_path(graph::AbstractGraph, src::Int64, dest::Int64)
    path = a_star(SimpleDiGraph(graph), src, dest, graph.weights)
    return path
end

function path_length(graph, path)::Float64
    dist = 0.0

    for edge in path
        dist += SimpleWeightedDiGraph(graph).weights[edge.src, edge.dst]
    end

    return dist
end

function greedy_multi_path!(graph::AbstractGraph, src::Int64, dest::Int64; maxpaths=2)
    paths = []

    for i in 1:maxpaths
        path = remove_shortest_path!(graph, src, dest)
        if length(path) == 0
            break
        else
            push!(paths, path)
        end
    end

    return paths
end

function remove_shortest_path!(graph::AbstractGraph, src::Int64, dest::Int64)
    path = shortest_path(graph, src, dest)

    for edge in path
        status = rem_edge!(graph, edge.dst, edge.src)
    end

    return path
end
