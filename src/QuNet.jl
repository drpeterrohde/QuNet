__precompile__(true)

module QuNet

using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs
using LinearAlgebra, StatsBase, Statistics
using Documenter, Colors, Plots, LaTeXStrings

import Base: *, print, string
import GraphPlot: gplot
export *

abstract type QObject end
abstract type QNode <: QObject end
abstract type QChannel <: QObject end

include("Network.jl")
include("CostVector.jl")
include("Node.jl")
include("Channel.jl")
include("TemporalGraphs.jl")
include("Percolation.jl")
include("Routing.jl")
include("Utilities.jl")
include("Benchmarking.jl")

end
