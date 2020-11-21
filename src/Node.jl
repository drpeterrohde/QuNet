function add(network::QNetwork, node::QNode)
    push!(network.nodes, node)
end

function update(node::QNode)
end

mutable struct Coords
    x::Float64
    y::Float64
    z::Float64

    Coords() = new(0,0,0)
    Coords(x,y) = new(x,y,0)
    Coords(x,y,z) = new(x,y,z)
end

mutable struct BasicNode <: QNode
    name::String
    costs::Dict
    memory::Dict
    id::Int64
    time::Int64
    active::Bool
    location::Coords

    BasicNode() = new("", ZeroCostVector(), UnitCostVector(), 0, 0, true, Coords())
    BasicNode(name) = new(string(name), ZeroCostVector(), UnitCostVector(), 0, 0, true, Coords())
end
