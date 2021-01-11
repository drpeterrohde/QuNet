mutable struct QNetwork <: QObject
    name::String
    nodes::Array{QNode}
    channels::Array{QChannel}
    # Dictionary between costs and corresponding weighted graphs.
    graph::Dict

    QNetwork() = new("QuNet", [], [], Dict())
end

function refresh_graph(network::QNetwork)
    network.graph = TemporalGraph(network, 1).graph
end

"""
    QNetwork(graph)

Network constructor from graph.
"""
function QNetwork(graph::AbstractGraph)
    network = QNetwork()

    vertexCount = 0
    for vertex in vertices(graph)
        vertexCount += 1
        add(network, BasicNode(string(vertexCount)))
    end

    edgeCount = 0
    for edge in edges(graph)
        edgeCount += 1
        add(network, BasicChannel(string(edgeCount), network.nodes[edge.src], network.nodes[edge.dst]))
        add(network, BasicChannel(string(edgeCount), network.nodes[edge.dst], network.nodes[edge.src]))
    end

    return network
end

function GridNetwork(dimX::Int64, dimY::Int64)
    graph = LightGraphs.grid([dimX,dimY])
    net = QNetwork(graph)

    for x in 1:dimX
        for y in 1:dimY
            this = x + (y-1)*dimX
            net.nodes[this].location = Coords(x,y)
        end
    end

    refresh_graph(net)
    return net
end

function update(network::QNetwork)
    for node in network.nodes
        update(node)
    end

    for channel in network.channels
        update(channel)
    end
end

function gplot(network::QNetwork)
    refresh_graph(network)

    locs_x = Vector{Float64}()
    locs_y = Vector{Float64}()

    for node in network.nodes
        push!(locs_x, node.location.x)
        push!(locs_y, node.location.y)
    end

    gplot(network.graph, locs_x, locs_y, arrowlengthfrac=0.04)
#   gplot(network.graph, locs_x, locs_y, nodelabel=1:nv(network.graph))
end
