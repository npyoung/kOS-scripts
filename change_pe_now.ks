// Parameters
parameter newpe.

// Imports
run once koslib.

if newpe < periapsis {
    set sign to -1.
} else {
    set sign to 1.
}

run point_at((sign * radial()):direction).

// Fix TWR
set twr to 0.2.
set mu to ship:body:mu.
set r to ship:body:radius + altitude.
set g to mu / r^2.
set throttle_target to max(twr * g * mass / maxthrust, 0.02).
print "Setting throttle to " + throttle_target.

until (sign * periapsis) > (sign * newpe) {
    lock throttle to throttle_target.
}

lock throttle to 0.
