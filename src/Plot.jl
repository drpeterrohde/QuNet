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


# function plot_network(tempnet::QuNet.TemporalGraph, user_paths)
#     # Get an instance of the graph from the tempgraph and plot the thing
#     graph = tempnet.graph["Z"]
#
#     # Visualisation coordinates specified by temporal graph
#     locs_x = tempnet.locs_x
#     locs_y = tempnet.locs_y
#
#     # Makeup bag
#     colour_pal = [colorant"lightgrey", colorant"orange", colorant"lightslateblue", colorant"green"]
#     # nodecolor = ["blue" for i in 1:nv(graph)]
#
#     # Presumably user_paths will have paths directed from async node to async node.
#     # Try removing these so that routing is no problem.
#
#     # Write a list of all the used edges, and write a dict of who they're used by:
#     used_edges = []
#     used_by = Dict()
#
#     this_user = 0
#     for paths in user_paths
#         this_user += 1
#         for path in paths
#             for edge in path
#                 push!(used_edges, edge)
#                 used_by[(edge.src,edge.dst)] = this_user
#             end
#         end
#     end
#
#     # Assign colors and edge properties
#     colours = []
#     widths = []
#     for edge in edges(graph)
#         if edge in used_edges
#             push!(colours, used_by[(edge.src,edge.dst)] + 1)
#             push!(widths, 5)
#         else
#             push!(colours, 1)
#             push!(widths, 1)
#         end
#     end
#
#     gplot(graph, locs_x, locs_y, edgestrokec=colour_pal[colours],
#     edgelinewidth=widths, arrowlengthfrac=0.04)#, layout=spring_layout)
# end
