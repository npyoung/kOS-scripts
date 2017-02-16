// Move toward a target while descending

// Parameters
parameter h_hover is 20.

// Imports
run once koslib.

// Set up ship
set debug to true.
set max_angle to 20.
lock steering to up.

// Set up constants
set u to ship:body:mu.
set r to ship:body:radius.
lock g to u / (r + ship:altitude)^2.
lock m to ship:mass.
lock h_err to vxcl(up:vector, target:position).

// Set up visual aids for testing
set err_arrow to vecdraw(V(0,0,0), h_err, RGB(1,0,0), "Error", 1.0, debug).
set steering_arrow to vecdraw(V(0,0,0), up:vector, RGB(0,1,0), "Steering", 1.0, debug).

// Set up velocity PID loops
set vPID to pidloop(2, 0, 0).
set hPID to pidloop(0.4, 0, 0).

until ship:status = "LANDED" and target:distance < 10 {
    // Figure out vertical acceleration request
    if h_err:mag > 0.2 {
        set vPID:setpoint to 0.
    } else {
        set vPID:setpoint to -2.
    }

    set a_max to ship:availablethrust / m.
    set a_v_max to a_max.
    set a_v to pos(min(a_v_max, g + vPID:update(time:seconds, vdot(up:vector, ship:velocity:surface)))).

    // Figure out horizontal acceleration request
    set v_h_desired to min(min(8, ship:groundspeed + 1), h_err:mag / 4) * h_err:normalized.
    set v_h to vxcl(up:vector, ship:velocity:surface).
    set v_h_err to v_h - v_h_desired.


    set a_h_max to min(sqrt(a_max^2 - a_v^2), a_v * tan(max_angle)).

    set a_h to min(a_h_max, hPID:update(time:seconds, v_h_err:mag)).

    // Combine vectors, aim, and thrust
    set a_vec to a_v * up:vector + a_h * v_h_err:normalized.

    lock steering to a_vec:direction.
    lock throttle to clip(a_vec:mag * m / ship:availablethrust, 0, 1).

    // Visualization
    set err_arrow:vec to h_err.
    set steering_arrow:vec to a_vec.

    wait 0.2.
}

lock throttle to 0.
killengines().
unlock steering.
disp("Touchdown!").
