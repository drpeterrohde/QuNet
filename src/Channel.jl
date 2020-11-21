function add(network::QNetwork, channel::QChannel)
    push!(network.channels, channel)
end

function update(channel::QChannel)
end

mutable struct BasicChannel <: QChannel
    name::String
    costs::Dict
    src::QNode
    dest::QNode
    active::Bool

    BasicChannel(src::QNode, dest::QNode) = new("", UnitCostVector(), src, dest, true)
    BasicChannel(name::String, src::QNode, dest::QNode) = new(string(name), UnitCostVector(), src, dest, true)
end

# mutable struct BasicMemory <: QChannel
#     node::QNode
#     costs::Dict
#
#     BasicMemory(node::QNode) = new(node, UnitCostVector())
#     BasicMemory(node::QNode, costs::Dict) = new(node, costs)
# end
