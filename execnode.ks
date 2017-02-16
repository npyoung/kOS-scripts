// Parameters
parameter slack is 30.


// Imports
run once koslib.

// Fixed parameters
set final_slack to 5.
set stage_wait to 3.

// Prepare the ship
clearscreen.
sas off.
set node to nextnode.

// figure out burn duration
set dob to burn_time(node:deltav:mag).
print "Estimated burn time: " + sec2timestr(dob).

// warp to burn time; give some slack for final steering adjustments
set hang to node:eta - dob / 2 - slack.
print "Warping ahead by " + sec2timestr(hang).

set twarpexit to time:seconds + hang.
if hang > 0 {
    set warpmode to "RAILS".
    warpto(twarpexit).
}


// estimate burn direction
set node_facing to lookdirup(node:deltav, facing:topvector).

// point ship at node
lock steering to lookdirup(node:deltav, facing:topvector).
wait until (vdot(facing:forevector, node_facing:forevector) >= 0.999 and ship:angularvel:mag < 0.01) or node:eta <= dob / 2.

// wait to fire
wait until time:seconds > twarpexit.
set warpmode to "PHYSICS".
set warp to 4.
wait until time:seconds > twarpexit + slack - final_slack.
set warp to 0.
set warpmode to "RAILS".
wait until time:seconds > twarpexit + slack.

set done to false.
set dv0 to node:deltav.
set dvmin to dv0:mag.
set th to 0.
lock throttle to th.

when availablethrust = 0 then {
    stage.
    set t0 to time:seconds.
    wait until stage:ready.
    if availablethrust = 0 {
        on time:seconds {
            if time:seconds > t0 + stage_wait {
                stage.
                return false.
            }
            return true.
        }
    }
}

until done {
    if (node:deltav:mag < dvmin) {
        set dvmin to node:deltav:mag.
    }

    // feather the throttle
    set accel to availablethrust / mass.
    if accel > 0 and mass > 0 {
        set th to clip(dvmin / accel, 0, 1.0).
        print "Requesting throttle of " + round(th, 1) at (0,15).
    }

    // three conditions for being done:
    //   1) overshot (node delta vee is pointing opposite from initial)
    //   2) burn DV increases (off target due to wobbles)
    //   3) burn DV gets too small for main engines to cope with
    set done to (vdot(dv0, node:deltav) < 0) or
              (node:deltav:mag > dvmin + 0.1) or
              (node:deltav:mag <= 0.2).
}

// Cleanup
lock throttle to 0.
unlock steering.
remove node.
