// Imports
run once koslib.

// Fixed parameters
set trajectory_path to "0:/compute_core/trajectory.json".
set state_path to "0:/compute_core/state.json".
set nominal_max_thrust = 0.8.
set compute_time to 15.

// Set up ship
sas off.
rcs on.
gear on.

if not hastarget {
    error("No target set").
}

// Write state
t0 = time:seconds + compute_time.
set state to lexicon().
posat = positionat(ship, t0).
velat = velocityat(target, t0):surface.
state["position"] = posat - target:position.
state["velocity"] = velat.
state["mdry"] = ship:drymass.
state["mwet"] = ship:wetmass.
state["Isp"] = available_isp().
state["Tmax"] = ship:availablethrust * nominal_max_thrust.
writejson(state ,state_path).

// Wait for trajectory
wait until exists(trajectory_path).
wait 0.25 // some time for the write to finish

// Read trajectory
trajectory = readjson(trajectory_path).

// TODO: parse this properly
for state in trajectory {
    t = state["t"].
    x = state["x"].
    v = state["x"].

    wait until time:seconds - t0 >= t.
    // TODO: achieve state
}
