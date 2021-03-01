using QuNet
using Plots

function get_costs_with_time(network::QNetwork, tmax::Float64, path::Array{<:QChannel, 1})
    # Initialise dictionary of costs over time
    costs = Dict()
    for key in keys(zero_costvector())
        costs[key] = []
    end

    # Main
    if network.time != Float64(0)
        update(network, Float64(0))
    end
    while network.time < tmax
        pathcost = get_pathcost(path)
        for key in keys(zero_costvector())
            push!(costs[key], pathcost[key])
        end
        update(network)
    end

    # Reset network back to default time
    update(network, Float64(0))

    # Return array of costs
    return [QuNet.dB_to_P.(costs["loss"]), QuNet.dB_to_Z.(costs["Z"])]
end

"""
This function takes a list of paths, purifies them and returns the costs over
time.
"""
function purify_costs_with_time(network::QNetwork, tmax::Float64,
    paths::Vector{Vector})

    loss_arr = []
    Z_arr = []

    if network.time != Float64(0)
        update(network, Float64(0))
    end

    while network.time < tmax
        path_costs = Array{Dict{Any, Any}, 1}()
        for path in paths
            path_cost = get_pathcost(path)
            push!(path_costs, path_cost)
        end

        # Purify path costs together, add to respective arrays
        cost_vector = purify(path_costs, false)
        push!(loss_arr, cost_vector["loss"])
        push!(Z_arr, cost_vector["Z"])

        # Update Network
        update(Q)
    end
    return loss_arr, Z_arr
end

function best_classical_z(cost1, cost2)
    best_arr = []
    i = 1
    maxint = length(cost1)
    while i <= maxint
        if cost1[i] > cost2[i]
            push!(best_arr, cost1[i])
        else
            push!(best_arr, cost2[i])
        end
        i += 1
    end
    return best_arr
end


# Main
Q = QNetwork()
A = BasicNode("A")
B = BasicNode("B")
S = PlanSatNode("S")

B.location = Coords(500, 0, 0)
S.location = Coords(-2000,0,1000)
S.velocity = Velocity(1000, 0)

AB = BasicChannel(A, B, exp_cost=true)
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

# Convert probabilities to loss
c1[1] = 1 .- c1[1]
c2[1] = 1 .- c2[1]

# function purify(cost_vectors::Array{Dict{String,Float64}, 1})
pur_loss, pur_z = purify_costs_with_time(Q, tmax, [[AS, SB], [AB]])
pur_loss = 1 .- pur_loss

# Get best classical cost
best_arr = best_classical_z(c1[2], c2[2])

# Plot data
plot(times, c1, title="Costs of Satellite Network over Time",
label=["A-S-B (loss)" "A-S-B (Z)"], linewidth=1.5, ylims=(0.0,1.0))
plot!(times, c2, label=["A-B (loss)" "A-B (Z)"], linewidth=1.5)

# Plot purified data
plot!(times, pur_loss, label="pur_loss", linewidth = 1.5)
plot!(times, pur_z, label="pur_z", linewidth = 1.5)

# Plot extraneous things
plot!(times, best_arr, label="best classical", style=:dash, lc="black", linewidth = 1.5)
xlabel!("Time (seconds)")
ylabel!("Network Costs")
