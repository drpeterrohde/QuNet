"""
Unit tests for QuNet

Hudson's style-guide convention for testing:

+ Redundency is good.
+ Don't aim to be redundant, but don't aim for tight scripting either.
+ If you want to manipulate a network from the network-library, (I.E. refreshing,
  adding temporal links, percolating etc.) do it on a copy.
+ One test set per file. Test every function in a given file thoroughly
+ Each test or subset of tests within the testset should begin with a comment
  briefly explaining what it's testing. Ideally, the test should work completely independently
  from other tests.
+ If you find something here that doesn't follow the style guide but it works regardless,
  don't change it.
+ Redundency is good

"""

using QuNet
using Test
using LightGraphs
using SimpleWeightedGraphs

# Perhaps put these includes in the unit tests so I don't have to refresh.
include("network-library/barbell.jl")
include("network-library/simple_network.jl")
include("network-library/simple_satnet.jl")
include("network-library/small_square.jl")
include("network-library/shortest_path_test.jl")
include("network-library/smalltemp.jl")

@testset "Network.jl" begin
    # Test: QNetwork is correctly initialised
    @test(typeof(barbell) == QNetwork)

    # Test: Nodes are correctly added
    @test length(barbell.nodes) == 2

    # Test: Channels are correctly added
    @test length(barbell.channels) == 1

    # Test: getnode works for id
    newnode = QuNet.getnode(barbell, 1)
    @test newnode == barbell.nodes[1]

    # Test: getnode works for name
    newnode = QuNet.getnode(barbell, "A")
    @test newnode == barbell.nodes[1]

    # Test: getchannel works for id
    newchannel = QuNet.getchannel(barbell, 1, 2)
    @test newchannel == barbell.channels[1]

    # Test: getchannel works for string
    newerchannel = QuNet.getchannel(barbell, "A", "B")
    @test newerchannel == barbell.channels[1]

    # Test: Update a sat network and check that the costs have changed
    AS = QuNet.getchannel(simple_satnet, "A", "S")
    old_costs = AS.costs
    update(simple_satnet)
    new_costs = AS.costs
    for key in keys(old_costs)
        @test old_costs[key] != new_costs[key]
    end

    # Test: Reset the network back to t=0 and check position goes back to init.
    S = QuNet.getnode(simple_satnet, "S")
    update(simple_satnet, 0.0)
    @test S.location.x == 500

    # Test: Check that deepcopy can clone network structure
    Q = deepcopy(barbell)
    @test all(Q.nodes[i] != barbell.nodes[i] for i in 1:length(Q.nodes))
    @test cmp(string(Q), string(barbell)) == 0

    # Test: refresh_graph! creates SimpleWeightedGraph copies of Network for all costs
    Q = deepcopy(barbell)
    QuNet.refresh_graph!(Q)
    @test length(Q.graph) == length(zero_costvector())
    g = Q.graph["Z"]
    @test nv(g) == 2
    @test ne(g) == 2
    @test g.weights[1, 2] == 0.5
    @test g.weights[2, 1] == 0.5

    # Test refresh_graph! on satellite network
    Q = deepcopy(simple_satnet)
    QuNet.refresh_graph!(Q)
    g = Q.graph["loss"]
    @test nv(g) == 3
    @test ne(g) == 4

    # Test 12: Test that update works on copied graph
    Q = deepcopy(barbell)
    update(Q)
    @test cmp(string(Q), string(barbell)) != 0

    # Test 13 / 14: Test that getchannel fetches the right channel in
    # a copied graph
    Q = deepcopy(barbell)
    AB = QuNet.getchannel(barbell, "A", "B")
    CAB = QuNet.getchannel(Q, "A", "B")
    @test (AB in barbell.channels) && (CAB in Q.channels)
    @test !(CAB in barbell.channels) && !(AB in Q.channels)
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
    # Test: convert_costs to decibelic form
    cost_vector = Dict("loss"=>0.5, "Z"=>0.5)
    dB_cv = convert_costs(cost_vector, false)
    @test (cost_vector["loss"] == 3.0102999566398116 &&
    cost_vector["Z"]== Inf)

    # Test: convert_cost from decibelic form
    metric_cv = convert_costs(cost_vector, true)
    @test cost_vector == metric_cv

    # Test: get_pathcv for a vector of QChannels
    Q = QNetwork()
    A = BasicNode("A")
    S = PlanSatNode("S")
    S.location = Coords(0,0,1000)
    C = AirChannel(A, S)
    for i in [A, S, C]
        add(Q, i)
    end
    cost_vector = get_pathcv([C])
    @test(cost_vector["loss"] == 0.4970454276591223 &&
    cost_vector["Z"]== 0.49694603901995044)

    # Test: get_pathcv for a single QChannel
    Q = deepcopy(barbell)
    channel = Q.channels[1]
    cv = get_pathcv(channel)
    @test(cv["loss"] == 1 && cv["Z"] == 0.5)

    # Test: get_pathcv for a QNetwork, and a path of Int tuples
    Q = deepcopy(simple_network)
    path = [(1,2),(2,3)]
    pathcv = get_pathcv(Q, path)
    @test pathcv["loss"] == 2 && pathcv["Z"] == 2

    # Test: get_pathcv for a TemporalGraph and a path of Int tuples
    T = deepcopy(smalltemp)
    path = [(1,5)]
    pathcv = get_pathcv(T, path)
    @test pathcv["loss"] == 1.0 && pathcv["Z"] == 1.0
end

@testset "Routing.jl" begin
    # Test: shortest_path for a SimpleWeightedDiGraph
    g = SimpleWeightedDiGraph(2)
    add_edge!(g, 1, 2, 3.14)
    short_path = shortest_path(g, 1, 2)
    @test(short_path[1] == SimpleWeightedEdge(1, 2, 3.14))

    # Test: path_length
    @test(3.14 == QuNet.path_length(g, short_path))

    # Test: remove_shortest_path! for a SimpleWeightedDiGraph
    removed_path_cost = QuNet.remove_shortest_path!(g, 1, 2)
    @test(removed_path_cost == 3.14)
    @test(length(edges(g)) == 0)

    # Test: remove_shortest_path! for a QNetwork returning path

    # Test: remove_shortest_path! for a QNetwork returning cost vector
    Q = deepcopy(shortest_path_test)
    refresh_graph!(Q)
    removed_path = QuNet.remove_shortest_path!(Q, "loss", 1, 2)
    @test(removed_path["Z"] == 10 && removed_path["loss"] == 2)

    # Test: remove_shortest_path! for a TemporalGraph returning path

    # Test: remove_shortest_path! for a TemporalGraph returning cost vector
    T = deepcopy(smalltemp)
    QuNet.add_async_nodes!(T)
    removed_cv = QuNet.remove_shortest_path!(T, "loss", 1, 2)
    @test removed_cv["loss"] == 1 && removed_cv["Z"] == 1
    @test has_edge(T.graph["loss"], 1, 2) == false
    # Remove shortest path again and test that the correct one was removed
    removed_cv = QuNet.remove_shortest_path!(T, "loss", 1, 2)
    @test removed_cv["loss"] == 1 && removed_cv["Z"] == 1
    # Remove shortest path once more.
    remove_cv = QuNet.remove_shortest_path!(T, "loss", 1, 2)
    remove_cv = QuNet.remove_shortest_path!(T, "loss", 1, 2)
    println(remove_cv)

    # # Test 5: new_greedy_multi_path
    # Q = QNetwork()
    # A = BasicNode("A")
    # C = BasicNode("C")
    # B = BasicNode("B")
    # AB = BasicChannel(A, B, exp_cost=false)
    # AC = BasicChannel(A, C, exp_cost=false)
    # CB = BasicChannel(C, B, exp_cost=false)
    # AB.costs = unit_costvector()
    # AC.costs = unit_costvector()
    # CB.costs = unit_costvector()
    #
    # for i in [A, B, C, AB, AC, CB]
    #     add(Q, i)
    # end
    #
    # refresh_graph!(Q)
    #
    # result, collisions = QuNet.greedy_multi_path!(Q, purify, "loss", [(1, 2)])
    # @test result[1]["loss"] == 0.37618793838911524
    #
    # # Test: that greedy_multi_path handles collisions when no edges exist
    # Q = QNetwork()
    # A = BasicNode("A")
    # B = BasicNode("B")
    # add(Q, A)
    # add(Q, B)
    # refresh_graph!(Q)
    # result, collisions = QuNet.greedy_multi_path!(Q, purify, "loss", [(1,2)])
    # @test result[1] == nothing
    # @test collisions == 1
    #
    # # Test:
    # ss = deepcopy(small_square)
    # result, collisions = QuNet.greedy_multi_path!(ss, purify, "loss",
    # [(1,2), (3,4)])
    # # println(result)
    # @test collisions == 0
    #
    # # Test: that greedy_multi_path! handles collisions when edges exist
    # ss = deepcopy(small_square)
    # result, collisions = QuNet.greedy_multi_path!(ss, purify, "loss",
    # [(1,3), (2,4)])
end

@testset "TemporalGraphs.jl" begin
    # Test 1: TemporalGraph initialises correctly
    G = GridNetwork(2, 2)
    T = QuNet.TemporalGraph(G, 2)
    @test nv(T.graph["loss"]) == 8
    @test T.nv == 4

    # Test TemporalGraph attribute memory_prob works
    G = GridNetwork(10, 10)
    T = QuNet.TemporalGraph(G, 2, memory_prob=0.0)
    @test ne(T.graph["Z"]) == 720

    # Test TemporalGraph adds 100 more edges when memory_prob = 100%
    T = QuNet.TemporalGraph(G, 2, memory_prob=1.0)
    @test ne(T.graph["Z"]) == 820

    # Test TemporalGraph with a default memory_cost, and check that temporal edges
    # Have that cost.
    T = QuNet.TemporalGraph(G, 2, memory_prob=1.0, memory_costs=Dict("Z"=>3, "loss"=>4))
    graph = T.graph["Z"]
    @test graph.weights[101, 1] == 3
    graph = T.graph["loss"]
    @test graph.weights[104, 4] == 4

    # Test add_async_nodes!
    G = GridNetwork(2, 2)
    T = QuNet.TemporalGraph(G, 2)
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
