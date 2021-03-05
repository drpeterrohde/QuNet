"""
Coordinates of the QNode object in up to three spatial dimensions
"""
mutable struct Coords
    x::Float64
    y::Float64
    z::Float64

    Coords() = new(0,0,0)
    Coords(x,y) = new(x,y,0)
    Coords(x,y,z) = new(x,y,z)
end

"""
The default QNode object. Nothing special, but nothing unspecial either ;-)"
"""
mutable struct BasicNode <: QNode
    name::String
    costs::Dict
    has_memory::Bool
    memory_costs::Dict
    id::Int64
    time::Int64
    active::Bool
    location::Coords

    BasicNode() = new("", zero_costvector(), true, zero_costvector(), 0, 0, true, Coords())
    BasicNode(name) = new(string(name), zero_costvector(), true, zero_costvector(), 0, 0, true, Coords())
end

"""
Add a QNode object to the network.

Example:

```
using QuNet
Q = QNetwork()
A = BasicNode("A")
add(Q, A)
```
"""
function add(network::QNetwork, node::QNode)
    push!(network.nodes, node)
    node.id = length(network.nodes)
end

"""
Remove a Qnode object from the network.

The convention for node removal in QuNet echos that of LightGraphs.jl.
Suppose a given network has N nodes, and we want to remove the node with the
id v:

1. Check if v < N . If false, simply pop the node from QNetwork.nodes
2. Else, swap the nodes v and N, then pop from QNetworks.nodes
"""
function remove(network::QNetwork, node::QNode)
    node_id = node.id
    if node_id != length(network.nodes)
        # Swap the node to be removed with the last node
        # (Same removal strategy as SimpleGraphs)
        tmp_node = deepcopy(node)
        N = last(network.nodes)
        node = N
        node.id = node_id
        N = tmp_node
    end
    pop!(network.nodes)
end

"""
```function update(node::QNode)```

Does nothing
"""
function update(node::QNode, old_time::Float64, new_time::Float64)
end


# Identical structure to Coords, but using a different name for distrinction
"""
```
mutable struct Velocity
    x::Float64
    y::Float64
    z::Float64

    Velocity() = new(0,0,0)
    Velocity(x,y) = new(x,y,0)
    Velocity(x,y,z) = new(x,y,z)
```

Type for Cartesian Velocity in up to 3 spatial coordinates
"""
mutable struct Velocity
    x::Float64
    y::Float64
    z::Float64

    Velocity() = new(0,0,0)
    Velocity(x,y) = new(x,y,0)
    Velocity(x,y,z) = new(x,y,z)
end

"""
```
mutable struct PlanSatNode <: QNode
    name::String
    costs::Dict
    memory::Dict
    id::Int64
    time::Int64
    active::Bool
    location::Coords
    velocity::Velocity
```

The `PlanSatNode` type has all the functionality of a `BasicNode` but can move
according to a fixed velocity.
"""
mutable struct PlanSatNode <: QNode
    name::String
    costs::Dict
    has_memory::Bool
    memory_costs::Dict
    id::Int64
    time::Int64
    active::Bool
    location::Coords
    velocity::Velocity
    PlanSatNode() = new("", zero_costvector(), true, unit_costvector(),
                    0, 0, true, Coords(), Velocity())
    PlanSatNode(name) = new(string(name), zero_costvector(), true, zero_costvector(),
                        0, 0, true, Coords(), Velocity())
end

"""
```function update(sat::PlanSatNode)```

Update the position of a planar satellite node by incrementing its current
location with the distance covered by its velocity in `TIME_STEP` seconds.
"""
function update(sat::PlanSatNode, old_time::Float64, new_time::Float64)
    # Calculate new position from velocity
    sat.location.x += sat.velocity.x * (new_time - old_time)
    sat.location.y += sat.velocity.y * (new_time - old_time)
    sat.location.z += sat.velocity.z * (new_time - old_time)
    return
end
