// Perform a suicide burn on an airless body.
// Attempts to make off-retrograde corrections while burning to hit a target.
// Depends: trajectories mod.

// Parameters
parameter margin is 500.
parameter finalv is 0.

// Imports
run once koslib.

// Fixed paramters
set forward_search_resolution to 5.
set backtracking_resolution to 0.1.
set craft_height to craft_height().
set glimit to 3.
set yaw_only to true.

// Set up ship
clearscreen.
set throttle_target to 0.
sas off.
lock throttle to throttle_target.
lock steering to srfretrograde.

// When will we hit the ground? Account for margin here.
set forward_search_resolution to 5.
set backtracking_resolution to 0.1.

function impact_time {
    parameter margin is 0.
    local guess_time is time:seconds.
    local terrain_alt is 0.
    local orbit_alt is altitude.

    // Forward search.
    until terrain_alt > orbit_alt {
        clearscreen.
        set guess_time to guess_time + forward_search_resolution.
        print "Checking t+" + (guess_time - time:seconds) at (0, 0).
        set terrain_alt to body:geopositionof(positionat(ship, guess_time)):terrainheight + margin.
        set orbit_alt to body:altitudeof(positionat(ship, guess_time)).
    }

    // Backtrack.
    until terrain_alt < orbit_alt {
        clearscreen.
        set guess_time to guess_time - backtracking_resolution.
        print "Checking t+" + (guess_time - time:seconds) at (0, 0).
        set terrain_alt to body:geopositionof(positionat(ship, guess_time)):terrainheight + margin.
        set orbit_alt to body:altitudeof(positionat(ship, guess_time)).
    }

    print "Final t+" + (guess_time - time:seconds) at (0,1).
    return guess_time.
}

// How fast will we be going at impact time? Account for final velocity here.
set impact_t to impact_time(margin).

// How fast will we be going at impact time?
set burn_dv to velocityat(ship, impact_t):surface:mag - finalv.
disp("Burn dv: " + round(burn_dv, 1)).

// When should we begin suicide burn?
set burn_t to burn_time(burn_dv).
disp("Burn duration: " + round(burn_t, 1) + "s").
set burn_start to impact_t - burn_t / 1.5.

// Wait until suicide burn time
lock steering to srfretrograde + R(0, 0, 180).
until time:seconds > burn_start {
    clearscreen.
    print "Burning in: " + sec2timestr(burn_start - time:seconds) at (0, 0).
    wait 0.2.
}

// Burn until final velocity reached while making corrections.
if yaw_only {
    set throttle_target to glimited_throttle(glimit).
    lock pitch to VANG(srfprograde:VECTOR, UP:VECTOR) - 90.
    lock pro to vang(srfprograde:vector, north:vector).
    lock targ to target:heading.
    lock compass to 2 * pro - targ + 180.
    lock steering to heading(compass, pitch).
} else {
    lock flip_around_prograde to angleaxis(180, srfprograde:vector).
    lock rev_aim to flip_around_prograde * target:direction.
    lock aim_vec to -rev_aim:vector.
    lock aim to aim_vec:direction.
    lock steering to aim.
}

lock throttle to 1.

wait until ship:velocity:surface:mag < abs(finalv).
//wait until vdot(ship:velocity:surface, up:vector) > finalv.

disp("Killing throttle").
lock throttle to 0.
