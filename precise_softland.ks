// Parameters
parameter h_hover is 50.
parameter v_final is -2.
parameter offset is 0.
parameter debug is false.

// Imports
run once koslib.

// Set up ship
sas off.
lock steering to up.

// Constants
set max_angle to 20.
set h_v_max to 12.

// Set up useful values
set u to ship:body:mu.
set r to ship:body:radius.
set height to craft_height().
lock g to u / (r + ship:altitude)^2.
lock m to ship:mass.
lock h_err to vxcl(up:vector, target:position + V(offset,offset,0)).
lock clearance to alt:radar - height.

// Set up visual aids for testing
set err_arrow to vecdraw(V(0,0,0), h_err, RGB(1,0,0), "Error", 1.0, debug).
set steering_arrow to vecdraw(V(0,0,0), up:vector, RGB(0,1,0), "Steering", 1.0, debug).

// Set up velocity PID loops
set vPID to pidloop(2, 0, 0).
set hPID to pidloop(0.1, 0, 0).

// Plan trajectory
set t_h to h_err:mag / h_v_max.
set descent_rate to -1 * (clearance - h_hover) / t_h.

until ship:status = "LANDED" and target:distance < 10 {
    // Figure out vertical acceleration request
    if clearance >= h_hover {
        set vPID:setpoint to descent_rate.
    } else if h_err:mag < 0.5 {
        set vPID:setpoint to v_final.
    } else {
        set vPID:setpoint to 0.
    }

    set a_max to ship:availablethrust / m.
    set a_v to pos(min(a_max, g + vPID:update(time:seconds, vdot(up:vector, ship:velocity:surface)))).

    // Figure out horizontal acceleration request
    set v_h_desired to min(min(h_v_max, ship:groundspeed + 1), h_err:mag / 10) * h_err:normalized.
    set v_h to vxcl(up:vector, ship:velocity:surface).
    set v_h_err to v_h - v_h_desired.

    set a_h_max to min(sqrt(a_max^2 - a_v^2), a_v * tan(max_angle)).

    set a_h to min(a_h_max, hPID:update(time:seconds, v_h_err:mag)).

    // Combine vectors, aim, and thrust
    set a_vec to a_v * up:vector + a_h * v_h_err:normalized.

    // For small thrusting, just point up
    set T to clip(a_vec:mag * m / ship:availablethrust, 0, 1).

    lock steering to a_vec:direction.
    lock throttle to clip(a_vec:mag * m / ship:availablethrust, 0, 1).

    // Visualization
    set err_arrow:vec to h_err.
    set steering_arrow:vec to a_vec.

    clearscreen.

    print "a_v: " at (1, 1).
    print round(a_v, 2) at (25, 1).

    print "a_h: " at (1, 2).
    print round(a_h, 2) at (25, 2).

    print "a_vec-mag " at (1, 3).
    print round(a_vec:mag, 2) at (25, 3).

    print "a_vec angle" at (1, 4).
    print round(vang(a_vec, up:vector), 1) at (25, 4).

    wait 0.2.
}

lock throttle to 0.
killengines().
unlock steering.
disp("Touchdown!").
