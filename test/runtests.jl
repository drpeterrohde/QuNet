# Are these declarations needed?
using QuNet
using Test
using LightGraphs
using SimpleWeightedGraphs

include("ExampleNetworks.jl")
include("small_square.jl")

@testset "Network.jl" begin
    # Test 1: QNetwork is correctly initialised
    @test(typeof(barbell) == QNetwork)

    # Test 2: Nodes are correctly added
    @test length(barbell.nodes) == 2

    # Test 3: Channels are correctly added
    @test length(barbell.channels) == 1

    # Test 4: add_qnode with default node
    # Q = QNetwork()
    # QuNet.add_qnode!(Q, nodename="A")
    # @test length(Q.nodes) == 1

    # Test 5: add_qnode with satellite node
    # QuNet.add_qnode!(Q, "S", PlanSatNode)
    # @test typeof(Q.nodes[2]) == PlanSatNode

    # Test 6: add_qchannel with AirChannel
    # QuNet.add_channel!(Q, "A", "S", type=AirChannel)
    # @test typeof(Q.channels[1]) == AirChannel

    # Test 4: getnode works for id
    newnode = QuNet.getnode(barbell, 1)
    @test newnode == barbell.nodes[1]

    # Test 5: getnode works for name
    newnode = QuNet.getnode(barbell, "A")
    @test newnode == barbell.nodes[1]

    # Test 6: getchannel works for id
    newchannel = QuNet.getchannel(barbell, 1, 2)
    @test newchannel == barbell.channels[1]

    # Test 7: getchannel works for string
    newerchannel = QuNet.getchannel(barbell, "A", "B")
    @test newerchannel == barbell.channels[1]

    # Test 8: Update a sat network and check that the costs have changed
    AS = QuNet.getchannel(simple_satnet, "A", "S")
    old_costs = AS.costs
    update(simple_satnet)
    new_costs = AS.costs
    for key in keys(old_costs)
        @test old_costs[key] != new_costs[key]
    end

    # Test 9: Reset the network back to t=0 and check position goes back to init.
    S = QuNet.getnode(simple_satnet, "S")
    update(simple_satnet, 0.0)
    @test S.location.x == 500

    # Test 10 / 11: Check that deepcopy can clone network structure
    C = deepcopy(barbell)
    @test all(C.nodes[i] != barbell.nodes[i] for i in 1:length(C.nodes))
    @test cmp(string(C), string(barbell)) == 0

    # Test 12: Test that update works on copied graph
    update(C)
    @test cmp(string(C), string(barbell)) != 0

    # Test 13 / 14: Test that getchannel fetches the right channel in
    # a copied graph
    AB = QuNet.getchannel(barbell, "A", "B")
    CAB = QuNet.getchannel(C, "A", "B")
    @test (AB in barbell.channels) && (CAB in C.channels)
    @test !(CAB in barbell.channels) && !(AB in C.channels)
end


@testset "Channel.jl"
    #Test Basic Channel is initalised with costs
    AB = BasicChannel(A, B)
    @test typeof(AB) == BasicChannel

    # Test AirChannel is a subtype of QChannel
    AS = AirChannel(A, S)
    @test typeof(AS) <: QuNet.QChannel
end


@testset "Node.jl"
    # Test Basic node is initalised
    A = BasicNode("A")
    @test A.name == "A"

    # Test node properties can be updated
    B = BasicNode("B")
    B.location = Coords(100, 0, 0)
    @test isequal(B.location.x, 100)

    # Test PlanSatNode is initialised
    S = PlanSatNode("S")
    S.location = Coords(0, 0, 1000)
    S.velocity = Velocity(1000, 0, 0)
end


@testset "Utilities.jl" begin
    # Test maximal coherence
    Z = 1.0
    dB = Z_to_dB(Z)
    @test dB == 0
    Zn = dB_to_Z(dB)
    @test Zn == 1

    # Test maximal decoherence
    Z = 0.5
    dB = Z_to_dB(Z)
    @test dB == Inf

    Z = dB_to_Z(dB)
    @test Z == 0.5

    # Test decoherence < 0.5
    Z = 0.3
    @test_throws DomainError Z_to_dB(Z)

    # Test Purification
    cv1 = Dict()
    cv2 = Dict()
    cv1["loss"] = 1.0
    cv2["loss"] = 2.0
    cv1["Z"] = 1.0
    cv2["Z"] = 2.0
    result = purify([cv1, cv2])
    println(result)

    # Test purification for paths
    Q = QNetwork()
    A = BasicNode("A")
    B = BasicNode("B")
    S = PlanSatNode("S")
    B.location = Coords(0, 1000, 0)
    S.location = Coords(0, 0, 1000)
    AB = BasicChannel(A, B, true)
    AS = AirChannel(A, S)
    results = QuNet.purify([AB, AS], false)
    print(results)
end


@testset "CostVector.jl" begin
    # Test 1: convert_costs to decibelic form
    cost_vector = Dict("loss"=>0.5, "Z"=>0.5)
    dB_cv = convert_costs(cost_vector, false)
    println(dB_cv)
    @test (cost_vector["loss"] == 3.0102999566398116 &&
    cost_vector["Z"]== Inf)

    # Test 2: convert_cost from decibelic form
    metric_cv = convert_costs(cost_vector, true)
    @test cost_vector == metric_cv

    # Test 3: get_pathcost
    Q = QNetwork()
    A = BasicNode("A")
    S = PlanSatNode("S")
    S.location = Coords(0,0,1000)
    C = AirChannel(A, S)
    for i in [A, S, C]
        add(Q, i)
    end
    cost_vector = get_pathcost([C])
    println(cost_vector)
    @test(cost_vector["loss"] == 0.4970454276591223 &&
    cost_vector["Z"]== 0.49694603901995044)

end

@testset "Routing.jl" begin
    # Test 1: shortest_path for a SimpleWeightedDiGraph
    g = SimpleWeightedDiGraph(2)
    add_edge!(g, 1, 2, 3.14)
    short_path = shortest_path(g, 1, 2)
    @test(short_path[1] == SimpleWeightedEdge(1, 2, 3.14))

    # Test 2: path_length
    @test(3.14 == QuNet.path_length(g, short_path))

    # Test 3 / 4: remove_shortest_path! for a SimpleWeightedDiGraph
    removed_path_cost = QuNet.remove_shortest_path!(g, 1, 2)
    @test(removed_path_cost == 3.14)
    @test(length(edges(g)) == 0)

    # Test 4: remove_shortest_path! for a QNetwork
    Q = QNetwork()
    A = BasicNode("A")
    B = BasicNode("B")
    AB = BasicChannel(A, B)
    AB.costs = Dict("loss"=>1, "Z"=>0.5)
    for i in [A, B, AB]
        add(Q, i)
    end
    refresh_graph!(Q)
    removed_path_cost = QuNet.remove_shortest_path!(Q, "loss", 1, 2)
    @test(has_path(Q.graph["loss"], 1, 2) == false)
    @test(removed_path_cost == Dict("Z"=>0.5, "loss"=>1.0))

    # Test: remove_shortest_path! for a TemporalGraph
    G = GridNetwork(2, 2)
    T = QuNet.TemporalGraph(G, 2)
    QuNet.add_async_nodes!(T)
    removed_path_cost = QuNet.remove_shortest_path!(T, "loss", 1, 2)
    @test has_edge(T.graph["loss"], 1, 2) == false

    # Test 5: new_greedy_multi_path
    Q = QNetwork()
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
        add(Q, i)
    end

    refresh_graph!(Q)

    result, collisions = QuNet.greedy_multi_path!(Q, purify, "loss", [(1, 2)])
    @test result[1]["loss"] == 0.37618793838911524

    # Test 6: that greedy_multi_path handles collisions when no edges exist
    Q = QNetwork()
    A = BasicNode("A")
    B = BasicNode("B")
    add(Q, A)
    add(Q, B)
    refresh_graph!(Q)
    result, collisions = QuNet.greedy_multi_path!(Q, purify, "loss", [(1,2)])
    @test result[1] == nothing
    @test collisions == 1

    # Test 7:
    ss = deepcopy(small_square)
    result, collisions = QuNet.greedy_multi_path!(ss, purify, "loss",
    [(1,2), (3,4)])
    # println(result)
    @test collisions == 0

    # Test 8: that greedy_multi_path! handles collisions when edges exist
    ss = deepcopy(small_square)
    result, collisions = QuNet.greedy_multi_path!(ss, purify, "loss",
    [(1,3), (2,4)])
    # println(result)
    # println(collisions)
    # TODO: Write some better tests here
end

@testset "TemporalGraphs.jl" begin
    # Test 1: TemporalGraph initialises correctly
    G = GridNetwork(2, 2)
    T = QuNet.TemporalGraph(G, 2)
    @test nv(T.graph["loss"]) == 8
    @test T.nv == 4

    # Test add_async_nodes!
    QuNet.add_async_nodes!(T)
    @test nv(T.graph["loss"]) == 12
    @test T.nv == 4

    # Test that edges are being added that connect async nodes to temporal ones
    src = 1
    src += T.nv * T.steps
    @test T.graph["loss"].weights[src, 1] == 1.0e-9
    @test T.graph["Z"].weights[5, src] == 2.0e-9

    # Test rem_async_nodes!
    QuNet.remove_async_nodes!(T)
    @test nv(T.graph["loss"]) == 8
end
