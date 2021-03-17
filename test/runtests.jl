"""
Unit tests for QuNet

Hudson's style convention for testing:

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

include_networks = ["barbell", "simple_network", "simple_satnet",
"small_square", "shortest_path_test", "smalltemp", "greedy_test", "bridge"]

for N in include_networks
    include("network-library/$N.jl")
end

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


@testset "Channel.jl" begin
    #Test Basic Channel is initalised with costs
    AB = BasicChannel(A, B)
    @test typeof(AB) == BasicChannel

    # Test AirChannel is a subtype of QChannel
    AS = AirChannel(A, S)
    @test typeof(AS) <: QuNet.QChannel
end


@testset "Node.jl" begin
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
    # TODO: Compare with hand calc
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
    removed_path, removed_path_cost = QuNet.remove_shortest_path!(g, 1, 2)
    @test(removed_path_cost == 3.14)
    @test(length(edges(g)) == 0)

    # Test: remove_shortest_path! for a QNetwork
    Q = deepcopy(shortest_path_test)
    removed_path, removed_cv = QuNet.remove_shortest_path!(Q, "loss", 1, 2)
    # Test removed path is correct
    shortestpath = [(1,3),(3,2)]
    shortestpath = QuNet.int_to_simpleedge(shortestpath)
    @test(shortestpath == removed_path)

    # Test removed path costs are correct
    @test(removed_cv["Z"] == 10 && removed_cv["loss"] == 2)

    # Test that the correct path was removed for both weighted graphs of the QNetwork
    # And check that edges are removed in both directions
    G = Q.graph["loss"]
    @test has_edge(G, 1, 3) == false && has_edge(G, 3, 1) == false &&
    has_edge(G, 3, 2) == false && has_edge(G, 2, 3) == false

    # Check that no nodes and no other edges were removed
    @test nv(G) == length(Q.nodes)
    @test ne(G) == (length(Q.channels) - 2) * 2

    G = Q.graph["Z"]
    @test has_edge(G, 1, 3) == false && has_edge(G, 3, 1) == false &&
    has_edge(G, 3, 2) == false && has_edge(G, 2, 3) == false

    # Check that no nodes and no other edges were removed
    @test nv(G) == length(Q.nodes)
    @test ne(G) == (length(Q.channels) - 2) * 2

    # Test: remove_shortest_path! for a TemporalGraph returning cost vector
    # and using asynchronus nodes
    T = deepcopy(smalltemp)
    src = 1+8
    dst = 2+8
    QuNet.add_async_nodes!(T, [(src, dst)])
    removed_path, removed_cv = QuNet.remove_shortest_path!(T, "loss", src, dst)
    # Test removed path is correct
    shortestpath = [(1,2)]
    shortestpath = QuNet.int_to_simpleedge(shortestpath)
    @test(shortestpath == removed_path)
    # Test removed path cost vectors is correct.
    @test removed_cv["loss"] == 1 && removed_cv["Z"] == 1

    # Remove shortest path again, and test that the path in the next temporal layer was removed
    removed_path, removed_cv = QuNet.remove_shortest_path!(T, "loss", src, dst)
    shortestpath = [(5,6)]
    shortestpath = QuNet.int_to_simpleedge(shortestpath)
    @test(shortestpath == removed_path)

    # Remove shortest path one final time:
    # test that the path now takes a longer route in first temporal layer
    removed_path, removed_cv = QuNet.remove_shortest_path!(T, "loss", src, dst)
    shortestpath = [(1,3),(3,4),(4,2)]
    shortestpath = QuNet.int_to_simpleedge(shortestpath)
    @test(shortestpath == removed_path)
    # test that the costs of this path are correct
    @test(removed_cv["loss"] == 3.0 && removed_cv["Z"] == 3.0)

    # Test that the correct path was removed for both weighted graphs of the TempNet
    # And check that edges are removed in both directions
    G = T.graph["loss"]
    @test has_edge(G, 1, 3) == false && has_edge(G, 3, 1) == false &&
    has_edge(G, 3, 4) == false && has_edge(G, 4, 3) == false &&
    has_edge(G, 4, 2) == false && has_edge(G, 2, 4) == false

    G = T.graph["loss"]
    @test has_edge(G, 1, 3) == false && has_edge(G, 3, 1) == false &&
    has_edge(G, 3, 4) == false && has_edge(G, 4, 3) == false &&
    has_edge(G, 4, 2) == false && has_edge(G, 2, 4) == false

    # Test: Check that no nodes and no other channels are removed for TempNet
    T = deepcopy(smalltemp)
    QuNet.add_async_nodes!(T, [(1, 2)])
    removed_path, removed_cv = QuNet.remove_shortest_path!(T, "loss", 1, 2)
    QuNet.remove_async_nodes!(T)

    G = T.graph["loss"]
    @test nv(G) == 8
    @test ne(G) == 18

    G = T.graph["Z"]
    @test nv(G) == 8
    @test ne(G) == 18

    #Test: greedy_multi_path
    Q = deepcopy(greedy_test)
    pathset, pur_paths, pathuse_count = QuNet.greedy_multi_path!(Q, purify, [(1, 2)])
    # Test that all three paths were purified together.
    @test pathuse_count == [0, 0, 0, 1]

    # Test that the pathset contains all the paths from "A" to "B"
    all_paths = [[(1,3),(3,2)], [(1,4), (4,2)], [(1,5), (5,2)]]
    new_pathset = []
    for path in pathset[1]
        path = QuNet.simpleedge_to_int(path)
        push!(new_pathset, path)
    end
    @test new_pathset == all_paths

    # Test: greedy_multi_path on a TemporalGraph with 2 asynchronus end-users
    T = deepcopy(smalltemp)
    offset = smalltemp.nv * smalltemp.steps
    src1 = 1 + offset
    dst1 = 4 + offset
    src2 = 2 + offset
    dst2 = 3 + offset
    QuNet.add_async_nodes!(T, [(src1, dst1), (src2, dst2)])
    pathset, pur_paths, pathuse_count = QuNet.greedy_multi_path!(T, purify, [(src1, dst1), (src2, dst2)])
    # Test that 2 edge-disjoint paths were found for each usepair
    @test(pathuse_count[3] == 2)
    # Test that the pathsets have the same destinations
    for bundle in pathset
        dsts = []
        for path in bundle
            push!(dsts, last(path).dst)
        end
        @test(all(i == dsts[1] for i in dsts))
    end

    # # Test: A grid lattice completely saturated with end-users has no purification
    # # i.e. no end-user used 2 or more paths
    # NOTE: I actually proved myself wrong on this one. Purification of 2 and even 3
    # Paths is possible depending on the choice of userpair. Will leave the code here
    # As proof:
    # Q = GridNetwork(10, 10)
    # userpairs = make_user_pairs(Q, 50)
    # pathset, purpaths, pathuse_count = QuNet.greedy_multi_path!(Q, purify, userpairs)
    # @test pathuse_count[3] == 0
    # @test pathuse_count[4] == 0

    # # Test that Greedy_multi_path and other routing algorithms can distinguish between
    # # The asynchronous edges of a temporal graph (i.e. prefering short times over long ones)
    # Q = deepcopy(bridge)
    # T = QuNet.TemporalGraph(Q, 2)
    # # Make asynchronus userpairs
    # QuNet.add_async_nodes!(T, [(13,17), (14,18)])
    # pathset, pur_paths, pathuse_count = QuNet.greedy_multi_path!(T, purify, [(13,17), (14,18)])
    # # Expected output: [[(1-3),(3-4),(4-5)],(2-8),(8-9),(9-10),(10-12)]
    # println(pathset)
end


@testset "TemporalGraphs.jl" begin
    # Test: TemporalGraph initialises correctly
    G = GridNetwork(2, 2)
    T = QuNet.TemporalGraph(G, 2)
    @test nv(T.graph["loss"]) == 8
    @test T.nv == 4

    # Test: TemporalGraph attribute memory_prob works
    G = GridNetwork(10, 10)
    T = QuNet.TemporalGraph(G, 2, memory_prob=0.0)
    @test ne(T.graph["Z"]) == 720

    # Test: TemporalGraph adds 100 more edges when memory_prob = 100%
    T = QuNet.TemporalGraph(G, 2, memory_prob=1.0)
    @test ne(T.graph["Z"]) == 820

    # Test TemporalGraph with a default memory_cost, check that temporal edges have that cost.
    T = QuNet.TemporalGraph(G, 2, memory_prob=1.0, memory_costs=Dict("Z"=>3, "loss"=>4))
    graph = T.graph["Z"]
    @test graph.weights[101, 1] == 3
    graph = T.graph["loss"]
    @test graph.weights[104, 4] == 4

    # Test add_async_nodes! for endusers that are both temporal
    G = deepcopy(barbell)
    T = QuNet.TemporalGraph(G, 3)
    @test T.has_async_nodes == false
    async_pairs = [(7,8)]
    QuNet.add_async_nodes!(T, async_pairs)
    @test nv(T.graph["loss"]) == 8
    @test nv(T.graph["Z"]) == 8
    @test T.nv == 2
    @test T.has_async_nodes == true

    # Test add_async_nodes! won't let you double dip. Uncomment for good warning
    # QuNet.add_async_nodes!(T, async_pairs)

    # Test that async edges were added to the correct nodes and in the proper directions
    g = T.graph["loss"]
    # async_pairs = [(7,8)]
    # usage: g.weights[dst, src]
    @test g.weights[1,7] != 0 && g.weights[7,1] == 0
    @test g.weights[2,8] == 0 && g.weights[8,2] != 0
    @test g.weights[3,7] != 0 && g.weights[7,3] == 0
    @test g.weights[4,8] == 0 && g.weights[8,4] != 0
    @test g.weights[5,7] != 0 && g.weights[7,5] == 0
    @test g.weights[6,8] == 0 && g.weights[8,6] != 0

    # Test add_async_nodes! for endusers where src is fixed on the top plane and dst is asynchronus
    G = deepcopy(barbell)
    T = QuNet.TemporalGraph(G, 2)
    async_pairs = [(1, 6)]
    QuNet.add_async_nodes!(T, async_pairs)
    g = T.graph["Z"]
    # Test that no async links were added to src
    @test g.weights[1,5] == 0 && g.weights[5,1] == 0

    # # Test that async links were added to dst and in proper direction
    # # usage: g.weights[dst, src]
    @test g.weights[6, 2] != 0 && g.weights[2, 6] == 0
    @test g.weights[6, 4] != 0 && g.weights[4, 6] == 0

    # Test remove_async_nodes!
    G = deepcopy(barbell)
    T = QuNet.TemporalGraph(G, 2)
    async_pairs = make_user_pairs(T, 1)
    QuNet.add_async_nodes!(T, async_pairs)
    QuNet.remove_async_nodes!(T)
    @test nv(T.graph["loss"]) == 4
    @test T.has_async_nodes == false

    # Test that remove_async_nodes! won't let you double dip
    # uncomment for a useful warning
    # QuNet.remove_async_nodes!(T)

    # Test fix async_nodes_in_time
    Q = deepcopy(barbell)
    depth = 5
    T = QuNet.TemporalGraph(Q, depth)
    src = 1 + 2*depth
    dst = 2 + 2*depth
    user_pairs = [(src, dst)]
    QuNet.add_async_nodes!(T, user_pairs)
    # Fix the third node
    QuNet.fix_async_nodes_in_time!(T, [3])

    g = T.graph["loss"]
    users = filter(isodd, 1:depth)
    for user in users
        if user == 3
            @test has_edge(g, src, user) == true
        else
            @test has_edge(g, src, user) == false
        end
    end

    # TODO: Not working
    # # Test remove_async_edges! for specific time layers
    # Q = deepcopy(barbell)
    # T = QuNet.TemporalGraph(Q, 5)
    # user_pairs = [(11, 12)]
    # QuNet.add_async_nodes!(T, user_pairs)
    # QuNet.remove_async_edges!(T, 3)
    # # Async_edges should have been removed at t = 3
    # g = T.graph["loss"]
    # src = 11; dst = 12
    # #usage g.weights[dst, src]
    # @test g.weights[1, src] != 0
    # @test g.weights[3, src] != 0
    # @test g.weights[5, src] == 0
    # @test g.weights[7, src] != 0

    # @test(has_path(g, src, 1) == true)
    # @test(has_path(g, src, 3) == true)
    # @test(has_path(g, src, 5) == false)
    # @test(has_path(g, src, 7) == true)

end


@testset "Benchmarking.jl" begin
    # TODO Test dict_average
    # TODO Test dict_err

    # Test make_user_pairs for QNetwork.

    # NOTE: One important detail I noticed:
    # make_user_pairs ordinarily generates random user pairs. I verified this in
    # A seperate test file. Impressively, the @testset seems to fix the seed, such
    # that no matter how many times you roll the dice, you get the same outcome.
    # Convenient for unit testing, not so much for verifying randomness.

    # Test make_user_pairs for a regular QNetwork
    Q = GridNetwork(2,2)
    user_pair = make_user_pairs(Q, 2)
    @test user_pair == [(4,3),(1,2)]

    # Test make_user_pairs for a TemporalGraph, specifying that pairs should be asynchronus
    G = deepcopy(barbell)
    T = QuNet.TemporalGraph(G, 2)
    async_pairs = QuNet.make_user_pairs(T, 1, src_layer=-1, dst_layer=-1)
    @test async_pairs == [(5,6)]

    # Test make_user_pairs for a TemporalGraph, specifying that src should be asynchronus, and dst on layer 1
    G = deepcopy(barbell)
    T = QuNet.TemporalGraph(G, 3)
    lopsided_pair = QuNet.make_user_pairs(T, 1, src_layer=-1, dst_layer=1)
    @test lopsided_pair[1][1] > T.nv * T.steps && lopsided_pair[1][2] <= T.nv

    # Test make_user_pairs for a TemporalGraph for many pairs, specifying dst should be asynchronus and src on arbitrary layer,
    G = GridNetwork(5,5)
    T = QuNet.TemporalGraph(G, 5)
    lopsided_pairs = QuNet.make_user_pairs(T, 10, src_layer=3, dst_layer=-1)
    @test all(T.nv * 2 < lopsided_pairs[i][1] <= T.nv * 3 for i in 1:10)
    @test all(T.nv * T.steps < lopsided_pairs[i][2] for i in 1:10)

    # Test ave_paths_used
    pathuse_count = [5,1,2,4]
    # Expected answer:
    # (0*5 + 1*1 + 2*2 + 3*4) / (5 + 1 + 2 + 4) == 17/12
    ave_pathuse = QuNet.ave_paths_used(pathuse_count)
    @test(ave_pathuse == 17/12)

    # TODO Test net_performance
    # Test for 1 trial of barbell network
    # usage: (network::QNetwork, num_trials::Int64, num_pairs::Int64; max_paths=3)
    Q = deepcopy(barbell)
    performance, performance_err, ave_pathcounts, ave_pathcounts_err = net_performance(barbell, 1, 1)
    # Check ave_pathcounts is correct
    @test ave_pathcounts == [0, 1, 0, 0]
    # Only one sample taken, so no variance in ave_pathcounts:
    @test all(isnan(i) == true for i in ave_pathcounts_err)

    # Test net_performance for many trials of barbell network
    Q = deepcopy(barbell)
    performance, performance_err, ave_pathcounts, ave_pathcounts_err = net_performance(barbell, 100, 1)
    @test ave_pathcounts == [0, 1, 0, 0]
    # Only one path possible, so no error
    @test ave_pathcounts_err == [0, 0, 0, 0]

    # Test net_performance for TemporalGraph
    T = deepcopy(smalltemp)
    performance, performance_err, ave_pathcounts, ave_pathcounts_err = net_performance(T, 100, 2)
    # Check that the average number of paths used is 2
    @test ave_pathcounts[3] == 2.0
    @test ave_pathcounts_err == [0.0, 0.0, 0.0, 0.0]
end
