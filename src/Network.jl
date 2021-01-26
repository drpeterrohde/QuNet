"""
The QNetwork type is a mutable structure that contains QNodes, QChannels, and
a dictionary of costs to weighted LightGraphs.
"""
mutable struct QNetwork <: QObject
    name::String
    nodes::Array{QNode}
    channels::Array{QChannel}
    # Dictionary between costs and corresponding LightGraphs weighted graphs.
    graph::Dict
    time::Float64

    # QNetwork() = new("QuNet", [], [], Dict())
    function QNetwork()
        network = new("QuNet", [], [], Dict(), 0.0)
        for cost_key in keys(zero_costvector())
            network.graph[cost_key] = SimpleWeightedDiGraph()
        end
        return network
    end
end

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

"""
    refresh(network::QNetwork, channel::QChannel)

Converts a QNetwork into several weighted LightGraphs (one
graph for each associated cost), then updates the QNetwork.graph attribute
with these new graphs.
"""
function refresh!(network::QNetwork)
    nv = length(network.nodes)
    for cost_key in keys(zero_costvector())
        network.graph[cost_key] = SimpleWeightedDiGraph()

        # Vertices
        add_vertices!(network.graph[cost_key], nv)

        # Channels
        for channel in network.channels
            src = findfirst(x -> x == channel.src, network.nodes)
            dest = findfirst(x -> x == channel.dest, network.nodes)
            weight = channel.costs[cost_key]
            add_edge!(network.graph[cost_key], src, dest, weight)
            if channel.directed == false
                add_edge!(network.graph[cost_key], dest, src, weight)
            end
        end
    end
end

"""
    GridNetwork(dim::Int64, dimY::Int64)

Generates an X by Y grid network.
"""
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

"""
```function update(network::QNetwork)```

The `update` function iterates through all objects in the network and updates
them with their relevant dispatch method, usually with respect to the global
fixed time increment `TIME_STEP`.

For more information about a specific update dispatch, try:
julia>?update(::<type>)
"""
function update(network::QNetwork)
    for node in network.nodes
        update(node)
    end

    for channel in network.channels
        update(channel)
    end
end

"""
    getnode(network::QNetwork, id::Int64)

Fetch the node object corresponding to the given ID / Name
"""
function getnode(network::QNetwork, id::Int64)
    return network.nodes[id]
end


function getnode(network::QNetwork, name::String)
    for node in network.nodes
        if node.name == name
            return node
        end
    end
end


"""
    getchannel(network::QNetwork, channel::QChannel)

    TODO:: Possibly redundent function when update() reaches full potential
    This function fetches a channel from a given network.

    Its main purpose is to get paths in a cloned network. For example, suppose
    C is a close of Q, and suppose we have a list of edges [e1, e2, e3] in Q.
    No [e1, e2, e3] is in C, so getChannel(C, e1) fetches the corresponding
    channel e1' in C.
"""
function getchannel(network::QNetwork, channel::QChannel)
    # Method 1: Slow + simple
    # Get nodes associated with channel
    # Iterate through channel list until find something that's matching
    for item in network.channels
        if item.src.id == channel.src.id
            if item.dest.id == channel.dest.id
                return item
            end
        end
    end
end
