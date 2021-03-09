"""
File to parse QNetwork with other graph types
"""

import SparseArrays:dropzeros!

"""
Remove both directions of the SimpleWeightedGraph edge properly as opposed
to just setting it to zero.
"""
function hard_rem_edge!(graph::SimpleWeightedDiGraph, src::Int64, dst::Int64)
    rem_edge!(graph, src, dst)
    rem_edge!(graph, dst, src)
    dropzeros!(graph.weights)
end

"""
Convert a path specifying node ints to a list of SimpleEdges
"""
function int_to_simpleedge(path::Vector{Tuple{Int, Int}})
    new_path = []
    for edge in path
        new_edge = LightGraphs.SimpleEdge(edge[1], edge[2])
        push!(new_path, new_edge)
    end
    return new_path
end

"""
Convert a path of SimpleEdges into a list of Int tuples
"""
function simpleedge_to_int(path::Vector{LightGraphs.SimpleEdge})
    new_path = []
    for edge in path
        new_edge = (edge.src, edge.dst)
        push!(new_path, new_edge)
    end
    return new_path
end
