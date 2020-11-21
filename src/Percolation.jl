function percolate_vertices(graph::AbstractGraph, p)::AbstractGraph
    return percolate_vertices(graph, p, [0])
end

function percolate_vertices(graph::AbstractGraph, p, exclude::Array{Int64})::AbstractGraph
    perc_graph = deepcopy(graph)

    for vertex in vertices(graph)
        # if !(vertex in exclude)
            if rand(Float64) <= p
                rem_vertex!(perc_graph, vertex)
            end
        # end
    end

    return perc_graph
end

function percolate_edges(graph::AbstractGraph, p)::AbstractGraph
    perc_graph = deepcopy(graph)

    for edge in edges(graph)
        if rand(Float64) <= p
            rem_edge!(perc_graph, edge)
        end
    end
 
    return perc_graph
end