"""
    add(network::QNetwork, channel::QChannel)

Add a channel to the network
"""
function add(network::QNetwork, channel::QChannel)
    push!(network.channels, channel)
end

function update(channel::QChannel, old_time::Float64, new_time::Float64)
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

    """
    Initalise a Basic Channel with unit costs
    """
    function BasicChannel(src::QNode, dest::QNode, ;exp_cost::Bool=false)
        tmpchannel = new("", unit_costvector(), src, dest, distance(src, dest), true, false)
        if exp_cost == true
            tmpchannel.costs = cost(tmpchannel)
        end
        return tmpchannel
    end

    function BasicChannel(name::String, src::QNode, dest::QNode, exp_cost::Bool=false)
        tmpchannel = new(name, unit_costvector(), src, dest, distance(src, dest), true, false)
        if exp_cost == true
            tmpchannel.costs = cost(tmpchannel)
        end
        return tmpchannel
    end

    #BasicChannel(src::QNode, dest::QNode) = new("", unit_costvector(), src, dest, distance(src, dest), true, false)
    #BasicChannel(name::String, src::QNode, dest::QNode) = new(string(name), unit_costvector(), src, dest, distance(src, dest), true, false)
end

function cost(channel::BasicChannel)
    d = channel.length
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


function update(channel::AirChannel, old_time::Float64, new_time::Float64)
    channel.length = distance(channel.src, channel.dest)
    channel.costs = cost(channel)
end

#     BasicMemory(node::QNode) = new(node, unit_costvector())
#     BasicMemory(node::QNode, costs::Dict) = new(node, costs)
# end
