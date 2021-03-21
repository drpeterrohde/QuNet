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
            push!(widths, 5)
        else
            push!(colours, 1)
            push!(widths, 1)
        end
    end

    mygplot = gplot(graph, locs_x, locs_y, edgestrokec=colour_pal[colours],
    edgelinewidth=widths, arrowlengthfrac=0.04)#, layout=spring_layout)
    # Save to pdf
    draw(PDF("plots/network_drawing.pdf", 16cm, 16cm), mygplot)
end


# TODO: Heatmap
function cost_heatmap()
    xs = [string("x", i) for i = 1:10]
    ys = [string("y", i) for i = 1:4]
    z = float((1:4) * reshape(1:10, 1, :))
    heatmap(xs, ys, z, aspect_ratio = 1)
end
