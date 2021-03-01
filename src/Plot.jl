using Cairo, Compose

function plot_network(graph::AbstractGraph, user_paths, locs_x, locs_y)
    used_edges = []
    used_by = Dict()

    colour_pal = [colorant"lightgrey", colorant"orange", colorant"lightslateblue", colorant"green"]

    # nodecolor = ["blue" for i in 1:nv(graph)]

    this_user = 0
    for paths in user_paths
        this_user += 1
        for path in paths
            for edge in path
                push!(used_edges, edge)
                used_by[(edge.src,edge.dst)] = this_user
            end
        end
    end

    colours = []
    widths = []
    for edge in edges(graph)
        if edge in used_edges
            push!(colours, used_by[(edge.src,edge.dst)] + 1)
            push!(widths, 100)
        else
            push!(colours, 1)
            push!(widths, 1)
        end
    end

    mygplot = gplot(graph, locs_x, locs_y, edgestrokec=colour_pal[colours],
    edgelinewidth=widths, arrowlengthfrac=0.04)#, layout=spring_layout)
    # Save to pdf
    draw(PDF("plot_network_output.pdf", 16cm, 16cm), mygplot)
end


"""
Plot the performance statistics of greedy-multi-path vs the number of end-user pairs
"""
function plot_with_userpairs(max_pairs::Int64,
    num_trials::Int64)

    perf_data = []
    collision_data = []
    path_data = []

    for i in 1:max_pairs
        println("Collecting for pairsize: $i")
        # Generate 10x10 graph:
        net = GridNetwork(10, 10)

        # Collect performance statistics
        performance, collisions, ave_paths_used = net_performance(net, num_trials, i)
        collision_rate = collisions/(num_trials*i)
        push!(collision_data, collision_rate)
        push!(perf_data, performance)
        push!(path_data, ave_paths_used)
    end

    # Get values for x axis
    x = collect(1:max_pairs)

    # Extract data from performance data
    loss_arr = collect(map(x->x["loss"], perf_data))
    z_arr = collect(map(x->x["Z"], perf_data))

    # Save data to csv
    file = "userpairs.csv"
    writedlm(file,  ["Average number of paths used",
                    path_data, "Efficiency", loss_arr,
                    "Z-dephasing", z_arr], ',')

    # Plot
    plot(x, collision_data, ylims=(0,1), linewidth=2, label=L"$P$",
    legend=:bottomright)
    plot!(x, loss_arr, linewidth=2, label=L"$\eta$")
    plot!(x, z_arr, linewidth=2, label=L"$F$")
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    savefig("cost_userpair.png")
    savefig("cost_userpair.pdf")

    plot(x, path_data, linewidth=2, legend=false)
    xaxis!(L"$\textrm{Number of End User Pairs}$")
    yaxis!(L"$\textrm{Average Number of Paths Used Per User Pair}$")
    savefig("path_userpair.png")
    savefig("path_userpair.pdf")
end
