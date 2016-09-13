// Parameters
parameter v_fast_approach is -16.

// Imports
run once koslib.

// Fixed parameters
set v_slow_approach to -6.
set v_final_approach to -2.
set high to 100.
set low to 10.

// Set up ship
clearscreen.
set throttle_target to 0.
lock throttle to clip(throttle_target, 0, 1).
run point_at(heading(90, 90)).
set height to craft_height().
lock clearance to alt:radar - height.
print "Craft is " + height + "m tall so clearance is " + clearance + "m".

// Determine gravitational acceleration at surface
set mu to ship:body:mu.
set r to ship:body:radius + alt:radar.
set g to mu / r^2.

// Wait till actually falling
print "Waiting until falling".
wait until verticalspeed < 0.
print "Falling".

// Initialize burn to cancel out gravity
set throttle_target to (g * mass) / maxthrust.
print "Locking throttle to: " + throttle_target.

// Transfer to PID control
set PID to PIDLOOP(0.04, 0.0, 0.04).
set vtarget to 0.

on vtarget {
    set PID:SETPOINT to vtarget.
    return true.
}
set vtarget to v_fast_approach.

when clearance < high then {
    set vtarget to v_slow_approach.
}
when clearance < low then {
    set vtarget to v_final_approach.
}

until verticalspeed > 0 or status = "LANDED"{
    set update to PID:UPDATE(TIME:SECONDS, verticalspeed).
    set throttle_target to throttle + update.
    clearscreen.
    print "Target speed is: " + vtarget at (0, 15).
    print "Adjusting thrust by: " + update at (0, 16).
    print "Throttle target is at: " + throttle_target at (0, 17).
    print "Clearance is: " + clearance at (0, 18).
    wait 0.01.
}

lock throttle to 0.

wait until status = "LANDED" and ship:angularvel:mag / 3.14 * 180 < 0.1.
print "Touchdown!".

print "Terminating in 5...".
wait 5.
