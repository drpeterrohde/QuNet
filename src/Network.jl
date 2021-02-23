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
    end

    return network
end

function print(network::QNetwork)
    println("name: ", network.name)
    println("nodes: ", length(network.nodes))
    println("channels: ", length(network.channels))
end

"""
    refresh_graph!(network::QNetwork)

Converts a QNetwork into several weighted LightGraphs (one
graph for each associated cost), then updates the QNetwork.graph attribute
with these new graphs.
"""
function refresh_graph!(network::QNetwork)
    network.graph = TemporalGraph(network, 1).graph
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

    refresh_graph!(net)
    return net
end

"""
```function update(network::QNetwork, new_time::Float64)```

The `update` function iterates through all objects in the network and updates
them according to a new global time.
"""
function update(network::QNetwork, new_time::Float64)
    old_time = network.time
    for node in network.nodes
        update(node, old_time, new_time)
    end

    for channel in network.channels
        update(channel, old_time, new_time)
    end
    network.time = new_time
end

"""
```function update(network::QNetwork)```

This instance of update iterates through all objects in the network and updates
them by the global time increment TIME_STEP defined in QuNet.jl
"""
function update(network::QNetwork)
    old_time = network.time
    new_time = old_time + TIME_STEP
    for node in network.nodes
        update(node, old_time, new_time)
    end

    for channel in network.channels
        update(channel, old_time, new_time)
    end
    network.time = new_time
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


function getchannel(network::QNetwork, src::Union{Int64, String},
    dst::Union{Int64, String})
    src = getnode(network, src)
    dst = getnode(network, dst)
    for channel in network.channels
        if channel.src == src && channel.dest == dst
            return channel
        end
    end
end

"""
function add_qnode!(network::QNetwork; nodename::String="", nodetype::DataType=BasicNode)
    @assert nodetype in subtypes(QNode)
    new_node = nodetype(nodename)
    add(network, new_node)
end
"""

"""
function add_channel!(network::QNetwork, src::Union{Int64, String},
    dst::Union{Int64, String};
    name::string="", type=BasicChannel)
    src = getnode(src)
    dst = getnode(dst)
    @assert type in [BasicChannel, AirChannel]
    new_channel = type(name, src, dst)
    add(network, new_channel)
end
"""
