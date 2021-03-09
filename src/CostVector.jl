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
    function get_pathcv(path::Array{<:QChannel, 1})

Returns a dictionary of costs for a path in a QNetwork. Not to be confused with
path_length(), which finds the scalar sum of weights for a path in an abstract graph.
"""
function get_pathcv(path::Vector{<:QChannel})
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

function get_pathcv(path::QChannel)
    get_pathcv([path])
end

function get_pathcv(network::QNetwork, path::Vector{Tuple{Int64, Int64}})::Dict{String, Float64}
    pathcost = Dict{String, Float64}()
    for cost_id in keys(zero_costvector())
        weight = 0.0
        for edge in path
            src = edge[1]
            dst = edge[2]
            weight += network.graph[cost_id].weights[src, dst]
        end
        pathcost[cost_id] = weight
    end
    return pathcost
end

function get_pathcv(temp::QuNet.TemporalGraph, path::Vector{Tuple{Int64, Int64}})::Dict{String, Float64}
    pathcost = Dict{String, Float64}()
    for cost_id in keys(zero_costvector())
        g = temp.graph[cost_id]
        pathcost[cost_id] = path_length(g, path)
    end
    return pathcost
end

function get_pathcv(network::Union{QNetwork, QuNet.TemporalGraph},
    path::Vector{LightGraphs.SimpleGraphs.SimpleEdge{Int64}})::Dict{String, Float64}

    new_path = Vector{Tuple{Int64, Int64}}()
    for edge in path
        new_edge = (edge.src, edge.dst)
        push!(new_path, new_edge)
    end
    pathcost = get_pathcv(network, new_path)
    return pathcost
end
