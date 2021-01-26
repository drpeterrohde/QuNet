using QuNet
using Plots

function get_costs_with_time(network::QNetwork, tmax::Float64, path::Array{<:QChannel, 1})
    # Copy network and path
    net_copy = deepcopy(network)
    path_copy = Array{QChannel, 1}()
    for item in path
        new_channel = QuNet.getchannel(net_copy, item)
        push!(path_copy, new_channel)
    end

    # Initialise dictionary of costs over time
    costs = Dict()
    for key in keys(zero_costvector())
        costs[key] = []
    end

    # Main
    t = 0
    while t < tmax
        pathcost = get_pathcost(net_copy, path_copy)
        for key in keys(zero_costvector())
            push!(costs[key], pathcost[key])
        end
        update(net_copy)
        t += QuNet.TIME_STEP
    end

    # Return array of costs
    return [QuNet.dB_to_P.(costs["loss"]), QuNet.dB_to_Z.(costs["Z"])]
end

function purify_costs_with_time(network::QNetwork, tmax::Float64, path1::Array{<:QChannel, 1},
    path2::Array{<:QChannel, 1})

    t = 0
    loss_arr = []
    z_arr = []
    while t < tmax
        pathcost1 = get_pathcost(network, path1)
        pathcost2 = get_pathcost(network, path2)
        loss, Z = purify([pathcost1, pathcost2], false)
        update(Q)
        t += QuNet.TIME_STEP
        push!(loss_arr, loss)
        push!(z_arr, Z)
    end
    return loss_arr, z_arr
end
"""
function test(network::QNetwork, tmax::Float64, paths::Vector{Vector{}})
    # Copy network and paths
    net_copy = deepcopy(network)
    paths_copy = [[] for i=1:length(paths)]

    for i in paths_copy
        for j in i
            new_channel = QuNet.getchannel(net_copy, j)
            push!(j, new_channel) = new_channel
        end
    end
    print(paths_copy)
end
"""


# Main
Q = QNetwork()
A = BasicNode("A")
B = BasicNode("B")
S = PlanSatNode("S")

B.location = Coords(500, 0, 0)
S.location = Coords(-2000,0,1000)
S.velocity = Velocity(1000, 0)

AB = BasicChannel(A, B)
AS = QuNet.AirChannel(A, S)
SB = QuNet.AirChannel(S, B)

for i in [A, S, AB, AS, SB]
    add(Q, i)
end

# Set time, get time array
tmax = 10.0
times = collect(0:QuNet.TIME_STEP:tmax)

# Collect data
c1 = get_costs_with_time(Q, tmax, [AS, SB])
c2 = get_costs_with_time(Q, tmax, [AB])

# Purify costs
# function purify(cost_vectors::Array{Dict{String,Float64}, 1})
pur_loss, pur_z = purify_costs_with_time(Q, tmax, [AS, SB], [AB])

plot(times, c1, title="Costs of Satellite Network over Time",
label=["A-S-B (loss)" "A-S-B (Z)"], linewidth=1.5, ylims=(0.0,1.0))
plot!(times, c2, label=["A-B (loss)" "A-B (Z)"], linewidth=1.5, ylims=(0.0,1.0))
plot!(times, pur_loss, label="pur_loss", linewidth = 1.5)
plot!(times, pur_z, label="pur_z", linewidth = 1.5)
xlabel!("Time (seconds)")
ylabel!("Network Costs")
