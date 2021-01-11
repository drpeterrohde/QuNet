include("QuNet.jl")

# Test 0: Initialising properly
println("Test 0: Hello world!\n")

# Test 1: Build an empty graph
net = QuNet.QNetwork()
println("Test 1: Print empty network")
print(net, "\n"^2)
# Can we format network object to print better? It's hard to read

# Test 2: Populate an empty graph with nodes
QuNet.add(net, QuNet.BasicNode("A"))
QuNet.add(net, QuNet.BasicNode("B"))
println("Test 2: Empty Graph")
print(net, "\n"^2)

# Needing to use QuNet.add is cumbersome and hard to read.
# Is there a workaround?

# Test 3: Add an edge to the graph
# Test 3.1 Get the node objects from string names

# How do we get the node labeled "A"?
# We can index I suppose, but we still need something like a table
# To keep track of index / names
A = net.nodes[1]
B = net.nodes[2]
println("Test 3.1: Get Nodes from Index")
print(A, B, "\n"^2)

# Test 3.2 Make a Basic Channel
println("Test 3.2: Make a Basic Channel")
C = QuNet.BasicChannel("C", A, B)
print(C, "\n"^2)

# Test 3.3 Add the Basic Channel to the graph
println("Test 3.3: Add the Basic Channel")
QuNet.add(net, C)
print(net, "\n^2")

# Test 3: Visualise the generic graph (No Coords specified)
# Seems like network has to have coordinates if to be plotted?
# QuNet.plot_network(net)

# Test 4: Generate a lattice graph and vary parameters

# Test 5: Generate a temporal lattice graph
