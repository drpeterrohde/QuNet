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
