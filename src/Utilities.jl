"""
Convert from decibelic loss to metric form
"""
function dB_to_P(dB::Float64)::Float64
    P = 10.0^(-dB/10)
    return P
end

"""
Convert from metric form to decibelic loss
"""
function P_to_dB(P::Float64)::Float64
    dB = -10.0*log(10,P)
    return dB
end

"""
Convert from dephasing probability to decibelic form
"""
function Z_to_dB(Z::Float64)::Float64
    dB = -10.0*log(10, 2*Z-1)
    return dB
end

"""
Convert from decibelic dephasing to metric form
"""
function dB_to_Z(dB::Float64)::Float64
    Z = (10^(-dB/10) + 1)/2
    return Z
end


function purify_PBS(F1::Float64,F2::Float64)::(Float64,Float64)
    F = F1*F1 / (F1*F2 + (1-F1)(1-F2))
    P = 1
    return (F,P)
end

function purify_CNOT(F1::Float64,F2::Float64)::(Float64,Float64)
    F = F1*F1 / (F1*F2 + (1-F1)(1-F2))
    P = 1
    return (F,P)
end

# This function purifies all vectors together
function purify(cost_vectors::Array{Dict{Any,Any}, 1}, return_as_dB::Bool=true)
    @assert keys(zero_costvector()) == keys(cost_vectors[1]) "Incompatible keys"
    p_arr = [dB_to_P(i["loss"]) for i in cost_vectors]
    z_arr = [dB_to_Z(i["Z"]) for i in cost_vectors]

    p = prod(p_arr) * (prod(z_arr) + prod(1 .- z_arr))
    z = prod(z_arr) / ((prod(z_arr) + prod(1 .- z_arr)))

    if return_as_dB == true
        return P_to_dB(p), Z_to_dB(z)
    else
        return p, z
    end
end
