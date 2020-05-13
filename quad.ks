LOCK pitch to 90 - vectorangle(SHIP:UP:FOREVECTOR, SHIP:FACING:FOREVECTOR).
LOCK roll to vectorangle(SHIP:UP:FOREVECTOR, SHIP:FACING:STARVECTOR) - 90.

SET pitch_pid to PIDLOOP(0.2, 0.0, 4.0).
SET roll_pid to PIDLOOP(0.2, 0.0, 4.0).

// Mid throttle is hover
SET fl to SHIP:PARTSTAGGED("FL")[0]:GETMODULE("ModuleRoboticServoRotor").
SET fr to SHIP:PARTSTAGGED("FR")[0]:GETMODULE("ModuleRoboticServoRotor").
SET bl to SHIP:PARTSTAGGED("BL")[0]:GETMODULE("ModuleRoboticServoRotor").
SET br to SHIP:PARTSTAGGED("BR")[0]:GETMODULE("ModuleRoboticServoRotor").
SET motors to list(fl, fr, bl, br).

// Initialize motors
// Assume homogenous motors types
SET max_rpm to 460.

FOR motor in motors {
    motor:SETFIELD("RPM Limit", 0.0).
    motor:SETFIELD("Torque Limit(%)", 100).
}.

UNTIL FALSE {
    // Command throttles
    SET command_throttles to list().
    FOR motor in motors {
        command_throttles:ADD(SHIP:CONTROL:PILOTMAINTHROTTLE * max_rpm) .
    }

    // Pitch adjustments
    SET pitch_pid:SETPOINT to 90 * SHIP:CONTROL:PILOTPITCH.
    SET pitch_adj to pitch_pid:UPDATE(TIME:SECONDS, pitch).
    SET command_throttles[0] to command_throttles[0] + pitch_adj.
    SET command_throttles[1] to command_throttles[1] + pitch_adj.
    SET command_throttles[2] to command_throttles[2] - pitch_adj.
    SET command_throttles[3] to command_throttles[3] - pitch_adj.

    // Roll adjustments
    SET roll_pid:SETPOINT to 90 * SHIP:CONTROL:PILOTROLL.
    SET roll_adj to roll_pid:UPDATE(TIME:SECONDS, roll).
    SET command_throttles[0] to command_throttles[0] + roll_adj.
    SET command_throttles[1] to command_throttles[1] - roll_adj.
    SET command_throttles[2] to command_throttles[2] + roll_adj.
    SET command_throttles[3] to command_throttles[3] - roll_adj.

    // Yaw adjustments
    SET roll_adj to max_rpm * 0.125 * SHIP:CONTROL:PILOTYAW.
    SET command_throttles[0] to command_throttles[0] - roll_adj.
    SET command_throttles[1] to command_throttles[1] + roll_adj.
    SET command_throttles[2] to command_throttles[2] + roll_adj.
    SET command_throttles[3] to command_throttles[3] - roll_adj.

    // Apply command command throttles
    SET motor_iter to motors:ITERATOR.
    UNTIL NOT motor_iter:NEXT {
        SET th to command_throttles[motor_iter:INDEX].
        motor_iter:VALUE:SETFIELD("RPM Limit", th).
    }.

    // Display info
    clearscreen.
    print "=== Quad control ===" at (0, 0).

    print "Pitch:    " + round(SHIP:CONTROL:PILOTPITCH, 2) at (0, 2).
    print "Roll:     " + round(SHIP:CONTROL:PILOTROLL, 2) at (0, 3).
    print "Yaw:      " + round(SHIP:CONTROL:PILOTYAW, 2) at (0, 4).
    print "Throttle: " + round(SHIP:CONTROL:PILOTMAINTHROTTLE, 2) at (0, 5).

    print "Front left:  " + round(command_throttles[0], 1) at (20, 2).
    print "Front right: " + round(command_throttles[1], 1) at (20, 3).
    print "Back left:   " + round(command_throttles[2], 1) at (20, 4).
    print "Back right:  " + round(command_throttles[3], 1) at (20, 5).

    print "Max RPM: " + round(max_rpm, 1) at (0, 7).
}

clearscreen.
