"""
Two end-user pairs (A1, B1) (A2, B2) are seperated by a single bridge (M1, M2)
which they'll have to compete for. 
"""
bridge = QNetwork()
A1 = BasicNode("A1")
A2 = BasicNode("A2")
M1 = BasicNode("M1")
M2 = BasicNode("M2")
B1 = BasicNode("B1")
B2 = BasicNode("B2")

A1M1 = BasicChannel(A1, M1)
A2M1 = BasicChannel(A2, M1)
M1M2 = BasicChannel(M1, M2)
M2B1 = BasicChannel(M2, B1)
M2B2 = BasicChannel(M2, B2)

for i in [A1M1, A2M1, M1M2, M2B1, M2B2]
    i.costs = unit_costvector()
end

for i in [A1, A2, M1, M2, B1, B2, A1M1, A2M1, M1M2, M2B1, M2B2]
    add(bridge, i)
end
refresh_graph!(bridge)
