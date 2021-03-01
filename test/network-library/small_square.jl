"""
Redundent code, should replace this in runtests when I get the chance
"""

small_square = QNetwork()
A = BasicNode("A")
B = BasicNode("B")
C = BasicNode("C")
D = BasicNode("D")
AB = BasicChannel(A, B)
BC = BasicChannel(B, C)
AD = BasicChannel(A, D)
DC = BasicChannel(D, C)

AB.costs = unit_costvector()
BC.costs = unit_costvector()
AD.costs = unit_costvector()
DC.costs = unit_costvector()

for i in [A, B, C, D, AB, BC, AD, DC]
    add(small_square, i)
end

refresh_graph!(small_square)
