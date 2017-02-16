// Hover at a set height

// Parameters
parameter h_hover is 20.

// Imports
run once koslib.

// Constants
set height to craft_height().
lock clearance to alt:radar - height.

// Set up ship
lock steering to up.

// Compute Z-N gains
set pi to constant:pi.
set u to ship:body:mu.
set r to ship:body:radius.
set g to u / r^2.
lock m to ship:mass.

set P to 2.
set I to 0.0.
set D to 0.0.

// Vertical PID
set vPID to pidloop(P, I, D).
set vPID:setpoint to 2.

when alt:radar >= h_hover then {
    set vPID:setpoint to 0.
    return false.
}

// Control loop
set over to false.
set t0 to time:seconds.

until ship:status = "LANDED" and over {
    if time:seconds - t0 > 20 {
        set over to true.
        set vPID:setpoint to -2.
    }
    set a_req to vPID:update(time:seconds, vdot(up:vector, ship:velocity:surface)).

    lock throttle to clip((a_req + g) * m / ship:availablethrust, 0, 1).

    wait 0.2.
}

lock throttle to 0.
