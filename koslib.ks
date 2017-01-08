// KOS LIB
// These are generally informational and convenience functions. They can stage,
// but generally don't point or throttle.

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

// Minimize a 1D pseudoconvex function via backtracking line search
function btls {
    parameter objective.
    parameter guess.
    parameter forward_step.
    parameter backward_step.

    local last is objective(guess).
    local now is last.

    // Forward search
    until now > last {
        set last to now.
        set guess to guess + forward_step.
        set now to objective(guess).
        clearscreen.
        print "Guess is " + guess at (0, 0).
    }

    // Backtrack.
    set last to now.

    until now > last {
        set last to now.
        set guess to guess - backward_step.
        set now to objective(guess).
        clearscreen.
        print "Guess is " + guess at (0, 0).
    }

    print "Final is " + guess at (0, 1).
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
            if eng:allowrestart {
                set float_tr to float_tr + eng:availablethrust.
            } else {
                set fixed_tr to fixed_tr + eng:availablethrust.
            }
        }
    }

    if fixed_tr + float_tr > 0 {
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
    return min(max(v, a), b).
}

// Determines the precise burn duration for a given dV.
function burn_time {
    parameter dv.
    parameter f is ship:availablethrust.
    local m is ship:mass.
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
        local t0 is time:seconds.
        when time:seconds > stage_coast + t0 then {
            stage.
            if maxthrust = 0 {
                disp(stage_wait + "s hold to clear debris").
                wait stage_wait.
                stage.
            }
        }
    } else {
        disp("BECO detected").
    }
    stage.
    wait until stage:ready.
    // If there are still no engines running
    // Decoupling and relighting are separate.
    // Wait to clear dropped stage, then firing up next stage.
    if maxthrust = 0 {
        disp(stage_wait + "s hold to clear debris").
        wait stage_wait.
        stage.
    }
}

// Human-readable time display function
function sec2timestr {
    parameter t.
    return (t + time - time):clock.
}
