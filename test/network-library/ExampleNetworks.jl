barbell = QNetwork()
A = BasicNode("A")
B = BasicNode("B")
AB = BasicChannel(A, B)
AB.costs = Dict("loss"=>1, "Z"=>0.5)
for i in [A, B, AB]
    add(barbell, i)
end
refresh_graph!(barbell)

simple_satnet = QNetwork()
S = PlanSatNode("S")
S.velocity = Velocity(100, 0, 0)
B.location = Coords(1000, 0, 0)
S.location = Coords(500, 0, 1000)
AS = AirChannel(A, S)
SB = AirChannel(B, S)
for i in [A, B, S, AS, SB]
    add(simple_satnet, i)
end
refresh_graph!(simple_satnet)
