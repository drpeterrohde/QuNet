function shortest_path(graph::AbstractGraph, src::Int64, dst::Int64)
    path = a_star(SimpleDiGraph(graph), src, dst, graph.weights)
    return path
end

function path_length(graph, path)::Float64
    dist = 0.0

    for edge in path
        dist += SimpleWeightedDiGraph(graph).weights[edge.src, edge.dst]
    end

    return dist
end

function greedy_multi_path!(graph::AbstractGraph, users::Array{Tuple{Int64,Int64}}; maxpaths=2)
    user_paths = []
    
    for user in users
        src = user[1]
        dst = user[2]

        paths = []

        for i in 1:maxpaths
            path = remove_shortest_path!(graph, src, dst)
            if length(path) == 0
                break
            else
                push!(paths, path)
            end
        end

        push!(user_paths, paths)    
    end

    return user_paths
end

function remove_shortest_path!(graph::AbstractGraph, src::Int64, dst::Int64)
    path = shortest_path(graph, src, dst)

    for edge in path
        status = rem_edge!(graph, edge.dst, edge.src)
    end

    return path
end
