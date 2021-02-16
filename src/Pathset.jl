"""
The pathset is an output of a routing method.

user_paths is a dictionary of end-user pairs to the corresponding path connecting
them. If no path exists, the tuple is empty.

path_costs is a dictionary of end-user pairs to the cost_vector associated with
the path.
"""
struct Pathset
    collisions::Int
    user_paths::Array(Tuple)
end
