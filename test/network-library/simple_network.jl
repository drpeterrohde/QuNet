simple_net = QNetwork()
A = BasicNode("A")
C = BasicNode("C")
B = BasicNode("B")
AB = BasicChannel(A, B, exp_cost=false)
AC = BasicChannel(A, C, exp_cost=false)
CB = BasicChannel(C, B, exp_cost=false)
AB.costs = unit_costvector()
AC.costs = unit_costvector()
CB.costs = unit_costvector()

for i in [A, B, C, AB, AC, CB]
    add(simple_net, i)
end
