// Parameters
parameter compass is 90.
parameter dump_stage is false.

// Fixed parameters
set min_throttle to 0.4.
set turn_twr to 1.75.
set turn_start to 200.
set turn_end to 4000.
set turn_angle to 15.
set tta_target to 45.
set frame_swap_alt to 30000.
set final_ap to 75000.
set stage_wait to 3.

// Physical constants
set g to 9.81.

// Prepare the ship
clearscreen.
SAS off.
RCS off.
lock bounded_throttle to 1.
lock throttle to max(min_throttle, min(1, bounded_throttle)).
lock steering to HEADING(compass, 90).
lock pitch to 90 - VANG(FACING:VECTOR, UP:VECTOR).
lock TWR to MAXTHRUST / (MASS * g).

// Autostaging logic
function anyflameout {
    list engines in all_engines.
    for engine in all_engines {
        if engine:flameout {
            return true.
        }
    }
    return false.
}

function handleflameout {
    if maxthrust = 0 {
        // This was the only active stage. Stage to separate,
        // then stage again to ignite next engine.
        print "MECO detected".
        stage.
        print stage_wait + "s hold until next stage ignition".
        wait stage_wait.
    } else {
        // These were radially-attached stages.
        // Just stage to separate.
        print "BECO detected".
    }
    stage.
}

// Launch
print "LAUNCH!".
stage.
when anyflameout() then {
    handleflameout().
    return true.
}

// Limit TWR
lock bounded_throttle to turn_twr * (MASS * g) / (MAXTHRUST + 0.001).

// Start turn
wait until ALT:RADAR > turn_start.
print "Forcing start of turn".
lock steering to HEADING(compass, 90 - turn_angle * (ALT:RADAR - turn_start) / (turn_end - turn_start)).

// Go prograde
wait until pitch < 90 - turn_angle + 0.5.
print "Initial turn done; holding prograde".
lock steering to SRFPROGRADE.

// Watch for switch to orbital prograde
when ALTITUDE > frame_swap_alt THEN {
    lock steering to PROGRADE.
    print "Swapping to orbital prograde".
}

// Switch from TWR limiting to time-to-Ap limting
wait until ETA:APOAPSIS > tta_target or APOAPSIS > final_ap.
print "TTAp target reached; throttling down".
set PID to PIDLOOP(0.02, 0.0, 0.02).
set PID:SETPOINT to tta_target.
until APOAPSIS > final_ap {
    set throttle_target to throttle + PID:UPDATE(TIME:SECONDS, ETA:APOAPSIS).
    print "throttle target is " + throttle_target at (0, 15).
    lock bounded_throttle to throttle_target.
    wait 0.1.
}
lock throttle to 0.

// Coast to Ap
set warpmode to "PHYSICS".
set warp to 4.
print "Coasting to Ap".
wait until ALTITUDE > body:atm:height.
set warpmode to "RAILS".
set warp to 0.

// Dump ascent stage if necessary
// Double check that this stage really is almost empty
set resource_lex to stage:resourceslex.
set lfuel to resource_lex["LiquidFuel"].
if dump_stage and lfuel:amount < 0.3 * lfuel:capacity {
    when periapsis > 50000 then {
        print "Dumping ascent stage".
        stage.
        wait until stage:ready.
        until availablethrust > 0 {
            stage.
            wait until stage:ready.
        }
    }
} else {
    print "Holding onto ascent stage".
}

// Circularize
run change_pe_at_ap(APOAPSIS).
run execnode.
