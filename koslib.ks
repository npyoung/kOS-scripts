// KOS LIB
// These are informational and convenience functions that do not exert any
// control action in the game.

// Get the ship normal direction
function normal {
    return vectorcrossproduct(prograde:vector, up:vector).
}

// Get the ship antinormal direction
function antinormal {
    return -1 * normal().
}

// Find height of cpu above bottom of craft.
function craft_height {
    list parts in partList.
    local lp is 0.//lowest part height
    local hp is 0.//hightest part height
    for p in partList{
        local cp is facing:vector * p:position.
        if cp < lp
            set lp to cp.
        else if cp > hp
            set hp to cp.
        }
    return hp - lp.
}

// Clip a value.
function clip {
    parameter v. // value
    parameter a. // low
    parameter b. // high
    return min(max(v, a), b).
}

// Determines the precise burn duration for a given dV.
function burn_time {
    parameter dv.
    local f is maxthrust.
    local m is mass.
    local e is constant:e.
    local i is available_isp().
    local g is 9.81.

    return g * m * i * (1 - e^(-dv / (g * i))) / f.
}

// Assuming only one type of ignited engine, gets current ISP.
function available_isp {
    list engines in all_engines.
    for engine in all_engines {
        if engine:ignition {
            return engine:ISP.
        }
    }
}

// Human-readable time display function
function sec2timestr {
    parameter t.
    return (t + time - time):clock.
}
