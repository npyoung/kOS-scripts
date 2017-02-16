// Final touchdown procedure for a vertical landing.
// Assumes nearly no horizontal velocity

// Parameters
parameter v_final is -2.

// Imports
run once koslib.

// Fixed parameters
set nominal_throttle to 0.5.
set glimit to 3.
set height to craft_height().

// Set up ship
clearscreen.
sas off.
set throttle_target to 0.
lock throttle to clip(throttle_target, 0, glimited_throttle(glimit)).
lock steering to up + R(0, 0, 180).
lock clearance to alt:radar - height - 2.

// Use ship parameters to guess a good P-term
set u to body:mu.
set r to body:radius + altitude.
set g to u / r^2.
set P to 2 * ship:mass * sqrt(g).
disp("Setting P=" + round(P, 4)).

// Figure out when to start linear velocity ramp
set a_max to nominal_throttle * max(9.81 * glimit, availablethrust / mass) - g.
set start_v to v_final - sqrt((a_max * clearance) / 2) + groundspeed.
disp("Waiting for vertical speed to fall below " + round(start_v, 1)).

// Point retrograde before firing
wait until verticalspeed < 0.
lock steering to srfretrograde + R(0, 0, 180).
wait until verticalspeed <= start_v.

// Transfer to PID control
set PID to PIDLOOP(P / nominal_throttle, 0.0, 0.0).

set throttle_target to 1.

until status = "LANDED" {
    set PID:SETPOINT to -sqrt(v_final^2 + pos(2 * a_max * clearance)).
    set update to PID:UPDATE(TIME:SECONDS, verticalspeed).
    set throttle_target to update / ship:availablethrust.

    clearscreen.
    print "Target speed:" at (0, 0).
    print round(PID:SETPOINT, 2) at (25, 0).

    print "Velocity error:" at (0, 1).
    print round(verticalspeed - PID:SETPOINT, 1) at (25, 1).

    print "Adjusting thrust to:" at (0, 2).
    print round(update, 0) at (25, 2).

    print "Throttle target:" at (0, 3).
    print round(throttle_target, 2) at (25, 3).

    print "Clearance:" at (0, 4).
    print round(clearance, 1) at (25, 4).
    wait 0.02.
}

lock throttle to 0.
unlock steering.
disp("Touchdown!").
