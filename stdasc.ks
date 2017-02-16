// Parameters
parameter final_ap is 75000.
parameter compass is 90.

// Imports
run once koslib.

// Fixed parameters
set roll to 180.
set stage_wait to 3.
set min_throttle to 0.4.
set g to 9.81.
set glimit to 2.5.
set turn_g to 1.65.
set turn_start to 100.
set turn_rate to 1.
set turn_hold to 5.
set tta_target to 60.
set dense_atm_alt to 7000.
set lower_atm_alt to 30000.
set fairing_alt to 40000.
set dump_pe to 20000.

// Prepare the ship
clearscreen.

// Bounded throttle obeys G-limit and min_throttle
lock max_throttle to glimited_throttle(turn_g).
set bounded_throttle to 1.
lock throttle to clip(bounded_throttle, min_throttle, max_throttle).

// Point up
lock pitch to 90 - VANG(FACING:VECTOR, UP:VECTOR).
lock steering to HEADING(compass, 90) + R(0, 0, roll).

// Launch
disp("LAUNCH!").
stage.
set advfohandling to true.
when anyflameout() then {
    return advfohandling and handleflameout().
}

// Use TWR to guess good turn angle
set twr to min(get_twr(), turn_g).
set turn_angle to (6 - 1.25) / (1.7 - 1.3) * (twr - 1.3) + 1.25.
disp("TWR is " + round(twr, 2)).
disp("Choosing " + round(turn_angle, 2) + " degree turn angle").

// Start turn
wait until ALT:RADAR > turn_start.
set turn_t to TIME:SECONDS.
disp("Forcing start of turn").
until pitch < 90 - turn_angle {
    set target_angle to  (TIME:SECONDS - turn_t) * turn_rate.
    lock steering to HEADING(compass, 90 - target_angle) + R(0, 0, roll).
}

// Stabilize the turn
lock steering to heading(compass, 90 - turn_angle) + R(0, 0, roll).
wait turn_hold.

// Go prograde
disp("Initial turn done; holding prograde").
lock steering to SRFPROGRADE + R(0, 0, roll).

// Watch for thinner atmosphere
when altitude > dense_atm_alt then {
    lock max_throttle to glimited_throttle(glimit).
    disp("Increasing g-limit").
}

// Watch for switch to orbital prograde
when ALTITUDE > lower_atm_alt THEN {
    lock steering to PROGRADE + R(0, 0, roll).
    disp("Swapping to orbital prograde").
}

// Watch for fairing drop if staged
when ALTITUDE > fairing_alt THEN {
    for module in ship:modulesnamed("ModuleProceduralFairing") {
        if module:part:stage = stage:number - 1 {
            disp("Dumping fairing").
            stage.
        }
    }
    wait until stage:ready.
    rcs on.
    set ag10 to true.
    disp("Deploying antennae (AG10)").
}

// Switch from TWR limiting to time-to-Ap targeting
disp("Begin time-to-Ap targeting mode").
set PID to PIDLOOP(0.008, 0.0, 0.16).
set PID:SETPOINT to tta_target.
until APOAPSIS > final_ap {
    set bounded_throttle to throttle + PID:UPDATE(TIME:SECONDS, ETA:APOAPSIS).
    print "Throttle target: " + round(bounded_throttle, 2) at (0, 1).
    wait 0.1.
}
lock throttle to 0.

// Coast to Ap
set warpmode to "PHYSICS".
set warp to 4.
disp("Coasting to Ap").
wait until ALTITUDE > body:atm:height.
set warpmode to "RAILS".
set warp to 0.

// Dump ascent stage if necessary
when periapsis > dump_pe then {
    // Double check that this stage really is almost empty
    set resource_lex to stage:resourceslex.
    if resource_lex:haskey("LiquidFuel") {
        set lfuel to resource_lex["LiquidFuel"].
        if dump_stage and lfuel:amount < 0.15 * lfuel:capacity {
            disp("Dumping ascent stage").
            killengines().
        } else {
            disp("Holding onto ascent stage").
        }
    }
}

// Circularize
run change_pe_at_ap(APOAPSIS).
set advfohandling to false.
run execnode.
