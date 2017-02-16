// Hover at a set height while translating to a target, then land

// Parameters
parameter h_hover is 200.

// Imports
run once koslib.

// Constants
set height to craft_height().
lock clearance to alt:radar - height.

// Compute Z-N gains
set pi to constant:pi.
set u to ship:body:mu.
set r to ship:body:radius + init_alt.
set g to u / r^2.
lock m to ship:mass.
lock Ku to g^2 * m / 5^2.
lock Tu to 2 * pi / (sqrt(Ku / m)).
set P to Ku / 5.
set I to Tu / 2.
set D to Tu / 3.

// Vertical PID
set vPID to pidloop(P, I, D).
set vPID:setpoint to h_hover.

// Horizontal PID
set hPID to pidloop(P, I, D).
set hPID:setpoint to 0.
lock herr to target:position.

// Set up visual aids for debugging
set err_arrow to vecdraw(V(0,0,0), herr, RGB(1,0,0), "Error", 1.0, true).
//set thrust_arrow to vecdraw(V(0,0,0), up:vector, RGB(0,1,0), "Thrust", 1.0, true).
set steering_arrow to vecdraw(V(0,0,0), up:vector, RGB(0,0,1), "Steering", 1.0, true).

// Run until landed
set vthrust_req to 0.
set hthrust_req to 0.
set over to false.
until ship:status = "LANDED" and over {
    if vxcl(up:vector, target:position):mag < 0.1 {
        set over to true.
        set vPID:setpoint to 0.
    }
    set vthrust_req to vPID:update(time:seconds, clearance).
    set hthrust_req to hPID:update(time:seconds, herr:mag).
    set thrust_vec to -1 * herr:normalized * hthrust_req + up:vector * vthrust_req.

    set err_arrow:vec to herr.
    set steering_arrow:vec to thrust_vec.

    lock steering to thrust_vec:direction.
    lock throttle to clip(thrust_vec:mag / ship:availablethrust, 0, 1).

    wait 0.2.
}
