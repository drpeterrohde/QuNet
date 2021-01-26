"""
    function zero_costvector()

Returns a dictionary of the default costs "loss" and "Z" both initialised to 0.
"""
function zero_costvector()::Dict
    costVector = Dict([("loss",0.0), ("Z",0.0)])
    return costVector
end

"""
    function unit_costvector()

Returns a dictionary of the default costs "loss" and "Z" both initialised to 1.
"""
function unit_costvector()::Dict
    costVector = Dict([("loss",1.0), ("Z",1.0)])
    return costVector
end

"""
    function get_pathcost(network::QNetwork, path::Array{<:QChannel, 1})

Returns a dictionary of costs the entirety of the QObjects contained in the
path.
"""
function get_pathcost(network::QNetwork, path::Array{<:QChannel, 1})
    cost_vector = Dict()
    for key in keys(zero_costvector())
        cost = 0
        cost = path[1].src.costs[key]
        for edge in path
            # Node costs
            cost += edge.dest.costs[key]
            # Edge costs
            cost += edge.costs[key]
        end
        cost_vector[key] = cost
    end
    return cost_vector
end
