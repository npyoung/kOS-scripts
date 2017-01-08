// Final touchdown procedure for a vertical landing.

// Parameters
parameter init_alt is 50.
parameter v_final is 0.

// Imports
run once koslib.

// Fixed parameters
set height to craft_height().

// Set up ship
clearscreen.
set throttle_target to 0.
lock throttle to throttle_target.
lock steering to up.
lock clearance to alt:radar - height.
disp("Craft is " + height + "m tall so clearance is " + clearance + "m").

// Wait till actually falling
if verticalspeed >= 0 {
    disp("Waiting until falling").
    wait until verticalspeed < 0.
    disp("Falling").
}

// Wait until initialization altitude
wait until clearance <= init_alt.
lock steering to srfretrograde.
set v0 to verticalspeed.

// Use ship parameters to guess a good P-term
set u to ship:body:mu.
set r to ship:body:radius + ship:altitude.
set g to u / r^2.
set P to 2 * ship:mass * sqrt(g).
disp("Setting P=" + P).

// Transfer to PID control
set PID to PIDLOOP(P, 0.0, 0.0).

until status = "LANDED"{
    set PID:SETPOINT to (v0 - v_final) / init_alt * clearance + v_final.
    set update to PID:UPDATE(TIME:SECONDS, verticalspeed).
    set throttle_target to update / ship:availablethrust.

    clearscreen.
    print "Target speed is: " + round(PID:SETPOINT, 2) at (0, 0).
    print "Adjusting thrust to: " + round(update, 0) at (0, 1).
    print "Throttle target is at: " + round(throttle_target, 2) at (0, 2).
    print "Clearance is: " + round(clearance, 1) at (0, 3).
    wait 0.02.
}

lock throttle to 0.
unlock steering.
disp("Touchdown!").
