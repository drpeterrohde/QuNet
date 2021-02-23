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
