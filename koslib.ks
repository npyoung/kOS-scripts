// KOS LIB
// These are generally informational and convenience functions. They can stage,
// but generally don't point or throttle.

function angdiff {
    parameter src.
    parameter tgt.
    set a to tgt - src.
    set a to mod(a + 180, 360) - 180.
    return a.
}

function term {
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
}

function str {
    parameter param_in.

    set param_in to param_in:replace("\''", char(34)).

    return param_in.
}

function runner {
    parameter name.
    if exists("run_helper.ks") {
        deletepath("run_helper.ks").
    }
    log str("run \''" + name + "\''.") to "run_helper.ks".

    run run_helper.ks.
}

function disp {
    parameter msg.
    parameter delay is 5.
    parameter style is 2.
    parameter size is 24.
    parameter color is green.
    parameter echo is false.
    hudtext(msg, delay, style, size, color, echo).
}

function warn {
    parameter msg.
    parameter delay is 5.
    parameter style is 2.
    parameter size is 24.
    parameter color is yellow.
    parameter echo is false.
    hudtext(msg, delay, style, size, color, echo).
}

function error {
    parameter msg.
    parameter delay is 10.
    parameter style is 2.
    parameter size is 36.
    parameter color is red.
    parameter echo is false.
    hudtext(msg, delay, style, size, color, echo).
}

// Time to closest approach with target
function closest_approach_eta {
    function distance_at_t {
        parameter t.
        return (positionat(ship, t) - positionat(target, t)):mag.
    }

    local start is time:seconds.

    return btls(distance_at_t@, start, 10, 0.1) - start.
}

function normang {
    parameter a.
    set a to posang(a).
    if a > 180 {
        set a to a - 360.
    }
    return a.
}

function posang {
    parameter a.
    return mod(a + 360, 360).
}

function pos {
    parameter x.
    return max(0, x).
}

function neg {
    parameter x.
    return min(0, x).
}

// Minimize a 1D pseudoconvex function via backtracking line search
function btls {
    parameter objective.
    parameter guess.
    parameter forward_step.
    parameter backward_step.
    parameter line is 0.

    local last is objective(guess).
    local now is last.

    // Forward search
    print "Forward search:" at (0, line).
    until now > last {
        set last to now.
        set guess to guess + forward_step.
        set now to objective(guess).
        print "Guessing " + round(guess, 2) at (0, line + 1).
        print "Obj is " + round(now, 2) at (0, line + 2).
    }

    // Backtrack.
    print "Backward search:" at (0, line + 3).
    set last to now.

    until now > last {
        set last to now.
        set guess to guess - backward_step.
        set now to objective(guess).
        print "Guessing " + round(guess, 2) at (0, line + 4).
        print "Obj is " + round(now, 2) at (0, line + 5).
    }

    return guess.
}

// Get the TWR relative to Kerbin's surface
function get_twr {
    set g to 9.81.
    return ship:availablethrust / (ship:mass * g).
}

// Get a G-limited throttle, accounting for SRBs
function glimited_throttle {
    parameter glimit.
    set g to 9.81.

    set fixed_tr to 0.
    set float_tr to 0.
    list engines in engs.
    for eng in engs {
        if eng:ignition {
            if eng:allowshutdown {
                set float_tr to float_tr + eng:availablethrust.
            } else {
                set fixed_tr to fixed_tr + eng:availablethrust.
            }
        }
    }

    if float_tr > 0 {
        return clip((glimit * g * ship:mass - fixed_tr) / float_tr, 0, 1).
    } else {
        return 1.
    }
}

// Get the ship radial direction
function radial {
    return vectorcrossproduct(prograde:vector, antinormal()).
}

// Get the ship normal direction
function antiradial {
    return -1 * radial().
}

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
    return max(min(v, b), a).
}

// Determines the precise burn duration for a given dV.
function burn_time {
    parameter dv.
    parameter thrust is ship:availablethrust.
    local f is thrust.
    local m is ship:mass.
    local e is constant:e.
    local i is available_isp().
    local g is 9.81.

    return g * m * i * (1 - e^(-dv / (g * i))) / f.
}

// Assuming only one type of ignited engine, gets current ISP.
// TODO: Can handle RCS thrust, if all RCS thruster included.
function available_isp {
    list engines in all_engines.
    for engine in all_engines {
        if engine:ignition {
            return engine:ISP.
        }
    }

    //list ship:modulesnamed("moduleRCSFX") in all_rcs.
    //for rcs_module in all_rcs {
    //    set rcs_part to rcs_module:part.
    //}
}

// Kill all ignited engine
function killengines {
    list engines in all_engines.
    for engine in all_engines {
        if engine:ignition {
            engine:shutdown().
        }
    }
}

// Autostaging logic
function anyflameout {
    list engines in all_engines.
    for engine in all_engines {
        if engine:flameout {
            return true.
        }
    }
    return false.
}

function handleflameout {
    // If there are no other engines running coast for a bit
    if maxthrust = 0 {
        disp("MECO detected").
        disp("Coasting for " + stage_coast + "s").
        set t0 to time:seconds.
        on time:seconds {
            print sec2timestr(time:seconds - t0) at (0, 2).
            if time:seconds > stage_coast + t0 {
                stage.
                disp(stage_wait + "s hold to clear debris").
                set t0 to time:seconds.
                when time:seconds > stage_wait + t0 then {
                    stage.
                    when anyflameout() then {
                        return handleflameout().
                    }
                }
                return false.
            }
            return true.
        }
    // If there are still engines running just decouple immediately.
    } else {
        disp("BECO detected").
        stage.
        return true.
    }
}

// Human-readable time display function
function sec2timestr {
    parameter t.
    return (t + time - time):clock.
}
