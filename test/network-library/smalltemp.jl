"""
A small 2x2 GridNetwork extended in time by 2 steps
All edges, including temporal ones, have unit costs
"""

using QuNet

g = GridNetwork(2,2)
smalltemp = QuNet.TemporalGraph(g, 2, memory_costs=unit_costvector())
