__precompile__(true)

module QuNet

using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs
using LinearAlgebra, StatsBase, Statistics
using Documenter, Colors, Plots, LaTeXStrings
using SatelliteToolbox, QuadGK

import Base: *, print, string
import GraphPlot: gplot

abstract type QObject end
abstract type QNode <: QObject end
abstract type QChannel <: QObject end

TIME_STEP = 0.01

include("Network.jl")
include("CostVector.jl")
include("Node.jl")
include("Channel.jl")
include("TemporalGraphs.jl")
include("Percolation.jl")
include("Routing.jl")
include("Plot.jl")
include("Utilities.jl")
include("Benchmarking.jl")

export
QObject, QNode, QChannel,

# Network.jl
QNetwork, GridNetwork, add, update,
refresh_graph,

# Plot.jl
gplot,

# CostVector.jl
zero_costvector, unit_costvector, get_pathcost,

# Channel.jl
BasicChannel, AirChannel,

# Node.jl
Coords, BasicNode, Velocity, PlanSatNode,

#Utilities.jl
dB_to_P, P_to_dB, Z_to_dB, dB_to_Z, purify
*

end
