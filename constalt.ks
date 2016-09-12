// Imports
run once koslib.

// Set up ship
clearscreen.
set throttle_target to 0.
lock throttle to throttle_target.

// Face orbital retrograde.
run point_at(retrograde).

// Throttle to full.
set throttle_target to 1.

// PID control
    // If vertical speed rises, pitch down
    // If vertical speed falls, pitch up
set PID to PIDLOOP(0.0004, 0.0, 0.002).
set PID:SETPOINT to 0.

set pitch to 90 - vang(facing:vector, up:vector).
lock compass to arccos(vdot(-up:topvector, srfretrograde:vector)) + 180.
print "Pitch detected: " + pitch.
print "Compass detected: " + compass.
lock steering to heading(compass, pitch).

// Continue until groundspeed is small
until ship:groundspeed < 20 {
    set ctrl_signal to PID:UPDATE(TIME:SECONDS, verticalspeed).
    set xfmd_signal to arcsin(clip(ctrl_signal, -1, 1)).
    print "Control signal: " + ctrl_signal at (0, 15).
    print "Pitch adjustment: " + xfmd_signal at (0, 16).
    set pitch to pitch + xfmd_signal.
    print "pitch target is " + pitch at (0, 17).
    wait 0.1.
}
set throttle_target to 0.

run suicideburn(200, -12).
run hoverthrust.
