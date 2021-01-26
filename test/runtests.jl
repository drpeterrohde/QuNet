using QuNet
using Test

@testset "QuNet.jl" begin
    # Test QNetwork is initialised
    Q = QNetwork()
    @test typeof(Q) == QNetwork

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

    # Test Basic Channel is initalised with costs
    AB = BasicChannel(A, B)
    @test typeof(AB) == BasicChannel

    # Test AirChannel is a subtype of QChannel
    AS = AirChannel(A, S)
    @test typeof(AS) <: QuNet.QChannel

    # Test QObjects are added to QNetwork
    for i in [A, B, S, AB, AS]
        add(Q, i)
    end

    @test length(Q.nodes) == 3
    @test length(Q.channels) == 2

    # Test that getnode works for id
    newnode = QuNet.getnode(Q, 1)
    @test newnode == Q.nodes[1]

    # Test that getnode works for name
    newnode = QuNet.getnode(Q, "S")
    @test newnode == S

    # Test get_pathcost
    path = [AB, AS]
    cost_vector = get_pathcost(Q, path)

    # Test update
    old_costs = AS.costs
    update(Q)
    new_costs = AS.costs
    for key in keys(old_costs)
        @test old_costs[key] != new_costs[key]
    end

    # Test deepcopy
    C = deepcopy(Q)
    @test all(C.nodes[i] != Q.nodes[i] for i in 1:length(C.nodes))
    @test cmp(string(C), string(Q)) == 0

    # Test update on copied graph
    update(C)
    @test cmp(string(C), string(Q)) != 0

    # Test aircost updated in copied graph but not in original
    C1 = Q.channels[2]
    C2 = C.channels[2]
    @test C1.costs["loss"] != C2.costs["loss"]

    # Test that getchannel fetches the right channel in a copied graph
    CAS = QuNet.getchannel(C, AS)
    @test (CAS.src.id == CAS.src.id) && (CAS.dest.id == CAS.dest.id)
    @test (AS in Q.channels) && (CAS in C.channels)
    @test !(CAS in Q.channels) && !(AS in C.channels)


end

@testset "Utilities.jl" begin
    # Test maximal coherence
    Z = Float64(1)
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
    cv1 = Dict{String, Float64}()
    cv2 = Dict{String, Float64}()
    cv1["loss"] = 1.0
    cv2["loss"] = 2.0
    cv1["Z"] = 1.0
    cv2["Z"] = 2.0
    result = purify([cv1, cv2])
    println(result)
end

@testset "CostVector.jl" begin
    # Test get_pathcost
    Q = QNetwork()
    A = BasicNode("A")
    S = PlanSatNode("S")
    S.location = Coords(0,0,1000)
    C = AirChannel(A, S)
    for i in [A, S, C]
        add(Q, i)
    end
    cost_vector = get_pathcost(Q, [C])
    println(cost_vector)
end
