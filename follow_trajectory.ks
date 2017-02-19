// Imports
run once koslib.

// Fixed parameters
set trajectory_path to "0:/compute_core/trajectory.json".
set Kp to 0.1.
set Kd to 0.5.
set accel_deadband to 0.2.
set debug to false.

// Set up ship
sas off.
rcs on.
gear on.
lock throttle to 0.
lock pos to ship:position - up:vector * craft_height().

if ship:status = "LANDED" or shiP:status = "PRELAUNCH" {
    lock steering to up.
} else {
    lock steering to srfretrograde.
}

if not hastarget {
    error("No target set").
}

// Display vectors
set traj_arrow to vecdraw().
set traj_arrow:show to debug.
set traj_arrow:color to RGB(0, 0, 1).
set traj_arrow:width to 0.8.

set u_arrow to vecdraw().
set u_arrow:show to debug.
set u_arrow:color to RGB(1, 0, 0).
set u_arrow:width to 0.8.

set true_arrow to vecdraw().
set true_arrow:show to debug.
set true_arrow:width to 0.8.

// Read trajectory
disp("Reading in trajectory.").
set trajectory to readjson(trajectory_path).

// Follow trajectory
set t0 to time:seconds.
for timept in trajectory {
    set t to timept["t"].
    set x to enu2xyz(timept["x"]).
    set v to enu2xyz(timept["v"]).
    set u to enu2xyz(timept["u"]).

    set x_true to pos - target:position.
    set v_true to ship:velocity:surface.

    if time:seconds - t0 < t {
        wait until time:seconds - t0 >= t.
    }

    set u_c to Kp * (x - x_true) + Kd * (v - v_true).
    set u_tot to u + u_c.

    lock throttle to u_tot:mag * ship:mass / ship:availablethrust.
    if u_tot:mag > accel_deadband {
        lock steering to u_tot:direction.
    }

    if debug {
        set traj_arrow:start to x - x_true.
        set traj_arrow:vec to v.

        set u_arrow:start to x - x_true.
        set u_arrow:vec to u.

        set true_arrow:vec to u_tot.
    }

    clearscreen.
    print "Lagging by:" at (0, 0).
    print round(time:seconds - t0 - t, 2) + "s" at (25, 0).

    print "x_err:" at (0, 1).
    set x_err to xyz2enu(x_true - x).
    print round(x_err:x, 1) at (25, 1).
    print round(x_err:y, 1) at (35, 1).
    print round(x_err:z, 1) at (45, 1).

    print "v_err:" at (0, 2).
    set v_err to xyz2enu(v_true - v).
    print round(v_err:x, 1) at (25, 2).
    print round(v_err:y, 1) at (35, 2).
    print round(v_err:z, 1) at (45, 2).

    //print "Directional error:" at (0, 3).
    //print round(vang(u_tot, xyz2enu(ship:facing:vector)), 1) + "deg" at (25, 3).
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
