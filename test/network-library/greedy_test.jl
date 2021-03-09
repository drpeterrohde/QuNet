"""
A graph to test greedy multi path routing
"""

greedy_test = QNetwork()
A = BasicNode("A")
B = BasicNode("B")
M1 = BasicNode("M1")
M2 = BasicNode("M2")
M3 = BasicNode("M3")

AM1 = BasicChannel(A, M1, exp_cost=false)
AM2 = BasicChannel(A, M2, exp_cost=false)
AM3 = BasicChannel(A, M3, exp_cost=false)
M1B = BasicChannel(M1, B, exp_cost=false)
M2B = BasicChannel(M2, B, exp_cost=false)
M3B = BasicChannel(M3, B, exp_cost=false)

AM1.costs = Dict("loss"=>0.5, "Z"=>0.5)
AM2.costs = Dict("loss"=>1.0, "Z"=>1.0)
AM3.costs = Dict("loss"=>1.5, "Z"=>1.5)
M1B.costs = Dict("loss"=>0.5, "Z"=>0.5)
M2B.costs = Dict("loss"=>1.0, "Z"=>1.0)
M3B.costs = Dict("loss"=>1.5, "Z"=>1.5)

for i in [A, B, M1, M2, M3, AM1, AM2, AM3, M1B, M2B, M3B]
    add(greedy_test, i)
end

refresh_graph!(greedy_test)
