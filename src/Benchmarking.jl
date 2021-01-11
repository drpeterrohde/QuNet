function percolation_bench(graph::AbstractGraph, incr::Float64, iter::Int64; type="edge")
    avs = []
    vars = []
    points = []
    exists = []

    p_range = 0:incr:1

    for p in p_range
        data = []
        for i in 1:iter
            if type=="edge"
                perc_graph = percolate_edges(graph, p)
            elseif type=="vertex"
                perc_graph = percolate_vertices(graph, p, [1,nv(graph)])
            else
                print("ERROR: Unknown percolation type.")
                return
            end
            path = shortest_path(perc_graph, 1, nv(graph))
            if length(path) != 0
                dist = path_length(perc_graph, path)
                push!(data, dist)
            end
        end

        p_exists = Float64(length(data)) / iter

        if length(data) != 0
            push!(points, p)
            push!(avs, mean(data))
            push!(vars, var(data))
        end

        push!(exists, p_exists)
    end

    p1 = plot(p_range, exists, legend=false, grid=true, xlims=(0,1), ylims=(0,1), lw=2, fillalpha=0.2)
    if type == "edge"
        xlabel!(L"p_\mathrm{edge}")
        ylabel!(L"p_\mathrm{path}")
        title!("Edge percolation")
    elseif type == "vertex"
        xlabel!(L"p_\mathrm{vertex}")
        ylabel!(L"p_\mathrm{path}")
        title!("Vertex percolation")
    end

    p2 = scatter(points, avs, yerror=vars, legend=false, grid=true, xlims=(0,1), ylims=(0,maximum(avs)), lw=2, fillalpha=0.2)
    if type == "edge"
        xlabel!(L"p_\mathrm{edge}")
        ylabel!(L"L")
        title!("Edge percolation")
    elseif type == "vertex"
        xlabel!(L"p_\mathrm{vertex}")
        ylabel!(L"L")
        title!("Vertex percolation")
    end

    return (p1,p2)
end

# Initialising correctly
function purify_bench(net::QNetwork,
                            users::Array{Tuple{Int64,Int64}},
                            maxpaths=2)
    println("Hello world!")
    QuNet.greedy_multi_path!(net, users, maxpaths)

    # Where are the costs stored?
end
