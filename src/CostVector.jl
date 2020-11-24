function ZeroCostVector()::Dict
    costVector = Dict([("loss",0), ("Z",0)])
    return costVector
end

function UnitCostVector()::Dict
    costVector = Dict([("loss",1), ("Z",1)])
    return costVector
end
