// Perform a suicide burn on an airless body.
// Does not account for steering losses, velocity picked up as a result of
// hang time added by the burn, or deceleration during the burn.

// Parameters
parameter margin is 100.
parameter finalv is 0.

// Imports
run once koslib.

// Fixed paramters
set forward_search_resolution to 5.
set backtracking_resolution to 0.1.
set craft_height to craft_height().
set glimit to 3.

// Set up ship
clearscreen.
set throttle_target to 0.
lock throttle to throttle_target.
lock steering to srfretrograde.

// When will we hit the ground? Account for margin here.
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
set burn_dv to velocityat(ship, impact_t):surface:mag + finalv.
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
}

// Burn until final velocity reached.
set throttle_target to glimited_throttle(glimit).
wait until verticalspeed >= finalv.
disp("Killing throttle").
lock throttle to 0.
