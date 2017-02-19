// Imports
run once koslib.

// Fixed parameters
set trajectory_path to "0:/compute_core/trajectory.json".
set state_path to "0:/compute_core/state.json".
set nominal_max_thrust to 0.8.
set compute_time to 10.
set Kp to 0.1.
set Kd to 0.5.
set accel_deadband to 0.2.
set physics_tick to 1/25.
set debug to false.

// Set up ship
sas off.
rcs on.
gear on.

if ship:status = "LANDED" or shiP:status = "PRELAUNCH" {
    lock steering to up.
} else {
    lock steering to srfretrograde.
}

if not hastarget {
    error("No target set").
}

if exists(trajectory_path) {
    disp("Removing old trajectory file").
    deletepath(trajectory_path).
}

// Write state
disp("Sending state information to the compute unit").
set t0 to time:seconds + compute_time.
set state to lexicon().
if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
    set future_x to ship:position - target:position.
    set future_v to V(0, 0, 0).
} else {
    set future_x to positionat(ship, t0) - target:position.
    set future_v to velocityat(ship, t0):surface.
}
set state["position"] to xyz2enu(future_x).
set state["velocity"] to xyz2enu(future_v).
set state["mdry"] to ship:drymass.
set state["mwet"] to ship:wetmass.
set state["Isp"] to available_isp().
set state["Tmax"] to ship:availablethrust * nominal_max_thrust.
set state["g"] to -body:mu / (body:radius + altitude)^2.
writejson(state ,state_path).

// Wait for trajectory
disp("Waiting on computations").
wait until exists(trajectory_path) or time:seconds > t0.
if time:seconds > t0 + compute_time {
    error("Computations timed out").
} else {
    wait 0.25. // some time for the write to finish
}

// Read trajectory
disp("Computations done! Reading in trajectory.").
set trajectory to readjson(trajectory_path).
disp("Preparing to follow trajectory in " + round(t0 - time:seconds, 1) + " seconds").

// Follow trajectory
for timept in trajectory {
    set t to timept["t"].
    set x to enu2xyz(timept["x"]).
    set v to enu2xyz(timept["v"]).
    set u to enu2xyz(timept["u"]).

    set x_true to pos - target:position.
    set v_true to ship:velocity:surface.

    if time:seconds - t0 + 2 * physics_tick < t {
        wait until time:seconds - t0 + physics_tick >= t.
    }

    set u_c to Kp * (x - x_true) + Kd * (v - v_true).
    set u_tot to u + u_c.

    lock throttle to u_tot:mag * ship:mass / ship:availablethrust.
    if u_tot:mag > accel_deadband {
        lock steering to u_tot:direction.
    }

    clearscreen.
    print "Lagging by:" at (0, 0).
    print round(time:seconds - t0 - t, 2) + "s" at (25, 0).

    print "x_err:" at (0, 1).
    set x_err to xyz2enu(x_true - x).
    print round(x_err:x, 1) at (25, 1).
    print round(x_err:y, 1) at (35, 1).
    print round(x_err:z, 1) at (45, 1).

    if debug {
        print "v_err:" at (0, 2).
        set v_err to xyz2enu(v_true - v).
        print round(v_err:x, 1) at (25, 2).
        print round(v_err:y, 1) at (35, 2).
        print round(v_err:z, 1) at (45, 2).

        print "Directional error:" at (0, 3).
        set ang to vang(u_tot, ship:facing:vector), 1)
        print round(ang, 1) + "deg" at (25, 3).
    }
}

// Any remaining distance
lock throttle to 0.
lock steering to up.
wait until ship:status = "LANDED".

// Prepare to return control
unlock steering.
killengines().
rcs off.
unlock throttle.
