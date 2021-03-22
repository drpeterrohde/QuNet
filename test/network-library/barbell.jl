barbell = QNetwork()
A = BasicNode("A")
B = BasicNode("B")
AB = BasicChannel(A, B)
AB.costs = Dict("loss"=>1, "Z"=>0.5)
for i in [A, B, AB]
    add(barbell, i)
end
refresh_graph!(barbell)
