function showtypetree(T, level = 0)
    println("\t"^level, last(split(string(T), ".")))
    for t in subtypes(T)
        showtypetree(t, level + 1)
    end
end

"""
Display the QuNet type tree
"""
function qunet_type_tree()
    showtypetree(QuNet.QObject)
end
