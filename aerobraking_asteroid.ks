// TODO:
// Parameters
// Better heuristic for last pass (current ap - 2 * last delta_ap < 70000)
// Automatically pack in and out solar panels
// "Dig out" periapsis when done.

clearscreen.

until apoapsis < 200000 {
    wait until altitude < 80000.
    print "Preparing for braking pass".
    set warp to 0.
    set roll to ship:facing:roll.
    lock steering to prograde + r(0,0,roll).
    set warpmode to "PHYSICS".
    set warp to 1.

    wait until abs(facing:pitch - prograde:pitch < 0.15 and abs(facing:yaw - prograde:yaw) < 0.15.
    print "Aligned for pass".
    set warp to 2.

    wait until altitude < 70000.
    print "Entering atmosphere".

    wait until altitude > 70000.
    print "Finished braking pass".
    set warp to 0.
    set warpmode to "RAILS".
    set warp to 3.

    if apoapsis > 120000 {
        wait until altitude > 120000.
        set warp to 4.
    }

    if apoapsis > 240000 {
        wait until altitude > 240000.
        set warp to 5.
    }
}

print "Done aerobraking".
