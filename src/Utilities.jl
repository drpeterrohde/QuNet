function dB_to_P(dB::Float64)::Float64
    P = 10^(-dB/10)
    return P
end

function P_to_dB(P::Float64)::Float64
    dB = -10*log(10,scalar)
    return dB
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
