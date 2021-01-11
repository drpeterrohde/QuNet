include("QuNet.jl")

# TODO
"""
1. Build a framework for updating graphs
    1.1. Create class of time dependent node elements
    1.2. For each corresponding time dependence, write a function
         describing how they evolve with each time step.
    1.3. Write script that iterates through the graph, updating the
         time dependent properties of the nodes, then iterates through
         and updates edges. An optional arguement will allow these
         graphs to be appended to a temporal metagraph
2. Build Satellite Struct (One for the Geodesic Satellite and One for
   the much simpler planar sat)
3. Visualisation tools.
    (?): Can we build something that animates the layers
         of the temporal meta-graph? We can have the relative costs indicated
         by colour intensity, but this won't communicate the full scope of
         states held in memory...
    3.1: In Qnet we had a simple function that noted the cost for a path at
         each timestep and plotted the curve of the costs. What about this time?

"""
mutable struct Velocity
    x::Float64
    y::Float64

mutable struct PlanSatNode <: QNode
    name::String
    costs::Dict
    memory::Dict
    id::Int64
    time::Int64
    active::Bool
    location::Coords
    velocity::Velocity
"""
