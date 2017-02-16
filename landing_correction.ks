// Correct to land almost exactly at a location on an airless body using one
// burn parallel to the surface.

// Imports
run once koslib.

// Set up ship
clearscreen.

function get_correction_burn {
    set g to body:mu / (body:radius + target:altitude)^2.
    set tgt_pos to target:position.
    set vel to velocity:surface.
    set vvel to vdot(-up:vector, vel). // vertical velocity
    set lvel to vxcl(-up:vector, vel). // lateral velocity
    set ldist to vxcl(-up:vector, tgt_pos). // lateral distance
    set vdist to vdot(-up:vector, tgt_pos). // vertical distance
    set ttg to (-vvel + sqrt(vvel^2 + 2 * vdist * g)) / g. // time to ground
    set lvelf to ldist / ttg. // final lateral velocity
    return lvelf - lvel.
}

set burn_angle to get_correction_burn():direction.
lock steering to burn_angle.

// Wait till actually falling
if verticalspeed >= 0 {
    disp("Waiting until falling").
    wait until verticalspeed < 0.
    disp("Falling").
}

set burn to get_correction_burn().
lock steering to burn:direction.
set burn_t to burn_time(burn:mag).
set t0 to time:seconds.
lock throttle to 1.
wait until time:seconds > t0 + burn_t.
lock throttle to 0.
