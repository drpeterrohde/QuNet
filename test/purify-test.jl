# purify-test
include("QuNet.jl")
new = QuNet.QNetwork()
users = [(1,1),(2,2)]

"""
function purify_bench(network::QNetwork,
                            users::Array{Tuple{Int64,Int64}},
                            maxpaths=2)
"""

new = QuNet.GridNetwork(5, 5)
gplot(new)
#QuNet.purify_bench(new, users)
# I get an error if I try to do something like network=new... Is it possible
# to write variable declarations?
