using QuNet

G = GridNetwork(10, 10)
T = QuNet.TemporalGraph(G, 2, memory_prob=1.0, memory_costs=Dict("Z"=>3, "loss"=>4))
println(T.graph["Z"])
graph = T.graph["Z"]
println(graph.weights[101, 1])

# Temporal
