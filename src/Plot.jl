function gplot(network::QNetwork, cost::String, uselocs::Bool=false)
    # refresh_graph(network)
    @assert cost in keys(zero_costvector()) "Invalid cost"

    # If using coordinates
    if uselocs == true
        locs_x = Vector{Float64}()
        locs_y = Vector{Float64}()

        for node in network.nodes
            push!(locs_x, node.location.x)
            push!(locs_y, node.location.y)
        end
        gplot(network.graph[cost], locs_x, locs_y)

    else
        layout = (args...)->spring_layout(args...; C=20)
        gplot(network.graph[cost], layout=layout, NODESIZE=0.2/network.graph[cost].nv)
        #gplot(network.graph, locs_x, locs_y, nodelabel=1:nv(network.graph))
    end
end


function plot_network(graph::AbstractGraph, user_paths, locs_x, locs_y)
    used_edges = []
    used_by = Dict()

    colour_pal = [colorant"lightgrey", colorant"orange", colorant"lightslateblue", colorant"green"]

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
            push!(widths, 5)
        else
            push!(colours, 1)
            push!(widths, 1)
        end
    end

    gplot(graph, locs_x, locs_y, edgestrokec=colour_pal[colours], edgelinewidth=widths, arrowlengthfrac=0.04)#, layout=spring_layout)
end
