// Parameters
parameter final_ap is 75000.
parameter compass is 90.
parameter dump_stage is true.

// Imports
run once koslib.

// Fixed parameters
set roll to 180.
set stage_wait to 3.
set min_throttle to 0.4.
set g to 9.81.
set glimit to 3.
set turn_g to 1.8.
set turn_start to 100.
set turn_rate to 1.
set turn_hold to 5.
set tta_target to 60.
set dense_atm_alt to 8000.
set lower_atm_alt to 30000.
set fairing_alt to 48000.
set dump_pe to 20000.
set stage_coast to 5.

// Set initial modes
set terminate to false.
set heading_mode to "init".
set throttle_mode to "init".
set stage_mode to "running".
set fairing_mode to "hold".
set comms_mode to "off".

// Prepare ship
clearscreen.
stage.
disp("Liftoff! We have liftoff!").

// Event loop
until terminate {
    // Staging subsystem
    if stage_mode = "running" {
        if anyflameout() {
            if maxthrust = 0 {
                disp("MECO detected").
                if ship:altitude < lower_atm_alt {
                    set stage_mode to "coast".
                    set coast_t0 to time:seconds.
                } else {
                    set stage_mode to "wait".
                    set clear_t0 to time:seconds.
                    stage.
                }
            } else {
                disp("BECO detected").
                stage.
            }
        }
    } else if stage_mode = "coast" {
        if time:seconds >= coast_t0 + stage_coast {
            set stage_mode to "wait".
            set clear_t0 to time:seconds.
            stage.
        }
    } else if stage_mode = "wait" {
        if time:seconds >= clear_t0 + stage_wait {
            set stage_mode to "running".
            stage.
        }
    }

    // Heading subsystem
    if heading_mode = "init" {
        lock steering to heading(compass, 90) + R(0, 0, roll).
        set heading_mode to "up".
    } else if heading_mode = "up" {
        if alt:radar >= turn_start {
            set heading_mode to "turning".
            set turn_t0 to time:seconds.
            set target_angle to 0.
            // Use TWR to guess good turn angle
            set twr to get_twr().
            set turn_angle to (6 - 1) / (1.8 - 1.3) * (twr - 1.3) + 1.
            lock steering to heading(compass, 90 - target_angle) + R(0, 0,roll).
            disp("Turn angle set to " + round(turn_angle, 2) + " degrees").
            disp("Forcing start of turn").
        }
    } else if heading_mode = "turning" {
        set target_angle to (time:seconds - turn_t0) * turn_rate.
        set pitch to 90 - vang(facing:vector, up:vector).
        if pitch < 90 - turn_angle {
            lock steering to heading(compass, 90 - turn_angle) + R(0, 0, roll).
            set heading_mode to "hold".
            set hold_t0 to time:seconds.
            disp("Holding turn attitude").
        }
    } else if heading_mode = "hold" {
        if time:seconds >= hold_t0 + turn_hold {
            lock steering to srfprograde + R(0, 0, roll).
            set heading_mode to "srfprograde".
            disp("Initial turn done, holding prograde").
        }
    } else if heading_mode = "srfprograde" {
        if altitude > lower_atm_alt {
            lock steering to prograde + R(0, 0 , roll).
            set heading_mode to "prograde".
            disp("Swapping to orbital prograde").
        }
    }

    // Throttle subsystem
    if throttle_mode = "init" {
        lock throttle to clip(1.0, min_throttle, glimited_throttle(turn_g)).
        set throttle_mode to "g_limiting".
    } else if throttle_mode = "g_limiting" {
        if altitude > dense_atm_alt {
            set throttle_mode to "tta_targeting".
            set PID to PIDLOOP(0.008, 0.0, 0.16).
            set PID:SETPOINT to tta_target.
            set throttle_target to throttle.
            lock throttle to clip(throttle_target, min_throttle, glimited_throttle(glimit)).
            disp("Switching from g-limiting to time-to-apoapsis targeting").
        }
    } else if throttle_mode = "tta_targeting" {
        set throttle_target to throttle + PID:UPDATE(TIME:SECONDS, ETA:APOAPSIS).
        print "Throttle target: " + round(throttle_target, 2) at (0, 1).
        if apoapsis >= final_ap {
            set throttle_mode to "coast".
            lock throttle to 0.
            set warpmode to "PHYSICS".
            set warp to 4.
            disp("Coasting out of atmosphere").
        }
    } else if throttle_mode = "coast" {
        if altitude >= body:atm:height {
            set warpmode to "RAILS".
            set warp to 0.
            set terminate to true.
        }
    }

    // Fairing subsystem
    if fairing_mode = "hold" {
        if ship:altitude > fairing_alt {
            set fairing_mode to "jettison".
        }
    } else if fairing_mode = "jettison" {
        for module in ship:modulesnamed("ModuleProceduralFairing") {
            if module:part:stage = stage:number - 1 {
                stage.
                disp("Dumping fairing").
            }
        }
        set fairing_mode to "jettisoned".
    }

    // Comms subsystem
    if comms_mode = "off" {
        if fairing_mode = "jettisoned" {
            set ag10 to true.
            disp("Deploying antennae (AG10)").
            set fairing_mode to "enabled".
        }
    }
}

run change_pe_at_ap(apoapsis).

// Dump ascent stage if necessary
when periapsis > dump_pe then {
    // Double check that this stage really is almost empty
    set resource_lex to stage:resourceslex.
    if resource_lex:haskey("LiquidFuel") {
        set lfuel to resource_lex["LiquidFuel"].
        if dump_stage and lfuel:amount < 0.15 * lfuel:capacity {
            disp("Dumping ascent stage").
            stage.
            wait until stage:ready.
            until availablethrust > 0 {
                stage.
                wait until stage:ready.
            }
        } else {
            disp("Holding onto ascent stage").
        }
    }
}

run execnode.
lock throttle to 0.
