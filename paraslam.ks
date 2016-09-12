// Parameters
parameter vhold is -4.
parameter powered_alt is 25.

// Imports
run once koslib.

// Set up ship
set throttle_target to 0.
lock throttle to clip(throttle_target, 0, 1).
lock steering to heading(90, 90).
set height to craft_height().
lock clearance to alt:radar - height.

// Open parachutes as they become safe
WHEN (NOT CHUTESSAFE) THEN {
    CHUTESSAFE ON.
    RETURN (NOT CHUTES).
}

// Set up PID
set PID to PIDLOOP(0.04, 0.0, 0.04).
set PID:SETPOINT to vhold.

// Wait to fall
print "Waiting to fall to " + powered_alt + "m".
wait until clearance < powered_alt.

// Transfer to powered control
until verticalspeed > 0 or status = "LANDED" {
    set update to PID:UPDATE(TIME:SECONDS, verticalspeed).
    set throttle_target to throttle + update.
    clearscreen.
    print "Target speed is: " + vhold at (0, 15).
    print "Adjusting thrust by: " + update at (0, 16).
    print "Throttle target is at: " + throttle_target at (0, 17).
    print "Clearance is: " + clearance at (0, 18).
    wait 0.01.
}

wait until status = "LANDED" and ship:angularvel:mag / 3.14 * 180 < 0.1.
print "Touchdown!".
