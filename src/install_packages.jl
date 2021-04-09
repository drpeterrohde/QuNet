using Pkg

dependencies = [
    "GraphRecipes",
    "LightGraphs",
    "SimpleWeightedGraphs",
    "GraphPlot",
    "MetaGraphs",
    "Documenter",
    "StatsBase",
    "LinearAlgebra",
    "Statistics",
    "Colors",
    "Plots",
    "LaTeXStrings",
    "Cairo",
    "Compose",
    "SparseArrays",
    "QuadGK",
    "SatelliteToolbox",
    "GR"]

Pkg.add(dependencies)
Pkg.update(dependencies)
