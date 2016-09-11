// Parameters
parameter margin is 500.

// Imports
run once koslib.

// Set up ship
clearscreen.
SAS off.
RCS off.
set throttle_target to 0.
lock throttle to throttle_target.
lock steering to srfretrograde.

// Determine gravitational acceleration at surface
set mu to ship:body:mu.
set r to ship:body:radius.
set g to mu / r^2.

// Figure out suicide burn height
set ttground to sqrt(2 * alt:radar / g).
set sbdv to g * ttground.
set sbduration to sbdv / (maxthrust / mass).
set sbalt to 0.5 * g * sbduration^2.
print "Suicide burn dv: " + sbdv.
print "Suicide burn travel: " + sbalt.

// Wait until suicide burn height
lock steering to srfretrograde.
lock alt_to_burn to alt:radar - sbalt - margin.

on alt_to_burn {
    print "Suicide burn in: " + alt_to_burn + "m" at (0, 15).
    return (alt_to_burn > 0).
}


wait until alt_to_burn < 0.

// Burn until vertical speed small.
set throttle_target to 1.
wait until verticalspeed > -4.
set throttle_target to 0.

// Hover down
run hoverthrust.
