"""
    add(network::QNetwork, channel::QChannel)

Add a channel to the network
"""
function add(network::QNetwork, channel::QChannel)
    push!(network.channels, channel)
    for cost_key in keys(zero_costvector())
        add_edge!(network.graph[cost_key], channel.src.id, channel.dest.id)
    end
end

"""
    refresh(network::QNetwork, channel::QChannel)

Write the QNetwork structure into LightGraph Weighted graphs, then "refresh"
the QNetwork.graph attribute with these new graphs.
"""
function refresh(network::QNetwork, channel::QChannel)
    for cost_key in keys(zero_costvector())
        add_edge!(network.graph[cost_key], channel.src.id, channel.dest.id)
        if directed == false
            add_edge!(network.graph[cost_key], channel.dest.id, channel.src.id)
        end
    end
end


function update(channel::QChannel)
end


"""
    distance(src::QNode, dest::QNode)

Cartesian distance between two nodes
"""
function distance(src::QNode, dest::QNode)
    v = src.location
    w = dest.location
    return sqrt((v.x - w.x)^2 + (v.y - w.y)^2 + (v.z - w.z)^2)
end


"""
    mutable struct BasicChannel <: QChannel

The default Channel type. Costs are assumed to be exponential with length
"""
mutable struct BasicChannel <: QChannel
    name::String
    costs::Dict
    src::QNode
    dest::QNode
    length::Float64
    active::Bool
    directed::Bool

    function BasicChannel(src::QNode, dest::QNode)
        tmpchannel = new("", unit_costvector(), src, dest, distance(src, dest), true, false)
        tmpchannel.costs = cost(tmpchannel)
        return tmpchannel
    end

    function BasicChannel(name::String, src::QNode, dest::QNode)
        tmpchannel = new(name, unit_costvector(), src, dest, distance(src, dest), true, false)
        tmpchannel.costs = cost(tmpchannel)
        return tmpchannel
    end

    #BasicChannel(src::QNode, dest::QNode) = new("", unit_costvector(), src, dest, distance(src, dest), true, false)
    #BasicChannel(name::String, src::QNode, dest::QNode) = new(string(name), unit_costvector(), src, dest, distance(src, dest), true, false)
end

function cost(channel::BasicChannel)
    d = channel.length
    α = 0.001
    β = 0.001
    loss = P_to_dB(exp(-β * d))
    Z = Z_to_dB((1 + exp(-β * d))/2)
    costVector = Dict([("loss",loss), ("Z",Z)])
    return costVector
end

mutable struct AirChannel <: QChannel
    name::String
    costs::Dict
    src::QNode
    dest::QNode
    length::Float64
    active::Bool
    directed::Bool

    function AirChannel(src::QNode, dest::QNode)
        tmpchannel = new("", unit_costvector(), src, dest, distance(src, dest), true, false)
        tmpchannel.costs = cost(tmpchannel)
        return tmpchannel
    end

    function AirChannel(name::String, src::QNode, dest::QNode)
        tmpchannel = new(name, unit_costvector(), src, dest, distance(src, dest), true, false)
        tmpchannel.costs = cost(tmpchannel)
        return tmpchannel
    end
end

function cost(channel::AirChannel)
    """
    Line integral for effective density

    / L'
    |     rho(x * sin(theta)) dx
    / 0
    """

    v = channel.src.location
    w = channel.dest.location
    L = channel.length
    # sin(theta)
    st = abs(v.z - w.z)/L
    # atmosphere function
    ρ = expatmosphere
    f(x) = ρ(x*st)
    # Effective atmospheric depth
    d = quadgk(f, 0, L)[1]

    β = 10e-5
    d₀ = 10e7

    # Calculate the decibelic forms of loss and Z
    P = exp(-β*d)*(d₀)^2/(d + d₀)^2
    Z = (1+exp(-β*d))/2

    # Put them in a cost vector and return
    costVector = Dict([("loss",P_to_dB(P)), ("Z",Z_to_dB(Z))])
    return costVector
end

function update(channel::AirChannel)
    channel.length = distance(channel.src, channel.dest)
    channel.costs = cost(channel)
end

#     BasicMemory(node::QNode) = new(node, unit_costvector())
#     BasicMemory(node::QNode, costs::Dict) = new(node, costs)
# end
