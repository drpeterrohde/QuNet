"""
    function zero_costvector()

Returns a dictionary of the default costs "loss" and "Z" both initialised to 0.
"""
function zero_costvector()::Dict
    costVector::Dict{String, Float64} = Dict([("loss",0.0), ("Z",0.0)])
    return costVector
end

"""
    function unit_costvector()

Returns a dictionary of the default costs "loss" and "Z" both initialised to 1.
"""
function unit_costvector()::Dict
    costVector::Dict{String, Float64} = Dict([("loss",1.0), ("Z",1.0)])
    return costVector
end


"""
Convert a cost vector to or from metric form
"""
function convert_costs(cost_vector::Dict, to_metric::Bool=true)
    if to_metric == true
        cost_vector["loss"] = dB_to_P(cost_vector["loss"])
        cost_vector["Z"] = dB_to_Z(cost_vector["Z"])
    else
        cost_vector["loss"] = P_to_dB(cost_vector["loss"])
        cost_vector["Z"] = Z_to_dB(cost_vector["Z"])
    end
    return cost_vector
end


"""
    function get_pathcost(path::Array{<:QChannel, 1})

Returns a dictionary of costs the entirety of the QObjects contained in the
path.
"""
function get_pathcost(path::Vector{<:QChannel})
    if length(path) == 0
        return zero_costvector()
    end
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

function get_pathcost(path::QChannel)
    get_pathcost([path])
end

function get_pathcost(graph::AbstractGraph, path::Vector{Tuple{Int64, Int64}})
    weight = 0
    for edge in path
        weight += graph.weights[edge[1], edge[2]]
    end
    return weight
end

function get_pathcost(network::QNetwork, path)
    pathcost = Dict{String, Float64}()
    for cost in keys(zero_costvector())
        weight = 0.0
        for edge in path
            src = edge.src
            dst = edge.dst
            weight += network.graph[cost].weights[src, dst]
        end
        pathcost[cost] = weight
    end
    return pathcost
end
