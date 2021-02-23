__precompile__(true)

module QuNet

# TODO: Update what we should be using vs importing. Be discriminating!.
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs
using LinearAlgebra, StatsBase, Statistics
using Documenter, Colors, Plots, LaTeXStrings

# using SatelliteToolbox
# using QuadGK

import SparseArrays:dropzeros!
import Base: *, print, string
import GraphPlot: gplot
import QuadGK: quadgk
import SatelliteToolbox: expatmosphere

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
include("GraphInterface.jl")

export
QObject, QNode, QChannel,

# Benchmarking.jl
percolation_bench,

# Channel.jl
BasicChannel, AirChannel,

# CostVector.jl
zero_costvector, unit_costvector, convert_costs, get_pathcost,

# Network.jl
QNetwork, GridNetwork, add, update,
refresh_graph!,

# Node.jl
Coords, BasicNode, Velocity, PlanSatNode,

# Percolation.jl

# Plot.jl
gplot,

# GraphInterface.jl
hard_rem_edge!,

# Routing.jl
shortest_path, greedy_multi_path!,

# TemporalGraphs.jl

# Utilities.jl
dB_to_P, P_to_dB, Z_to_dB, dB_to_Z, purify

end
