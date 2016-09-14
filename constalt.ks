// Parameters
parameter end_hv is 20.

// Imports
run once koslib.

// Set up ship
clearscreen.
set throttle_target to 0.
lock throttle to throttle_target.

// Set up PID
set PID to PIDLOOP(0.0004, 0.0, 0.002).
set PID:SETPOINT to 0.

// Face orbital retrograde.
run point_at(retrograde).
set pitch to 90 - vang(facing:vector, up:vector).
lock compass to arccos(vdot(-up:topvector, srfretrograde:vector)) + 180.
print "Pitch detected: " + pitch.
print "Compass detected: " + compass.
lock steering to heading(compass, pitch).

// Throttle to full.
set throttle_target to 1.

// If vertical speed rises, pitch down
// If vertical speed falls, pitch up
// Continue until groundspeed is small
until ship:groundspeed < end_hv {
    clearscreen.
    set ctrl_signal to PID:UPDATE(TIME:SECONDS, verticalspeed).
    set xfmd_signal to arcsin(clip(ctrl_signal, -1, 1)).
    set pitch to pitch + xfmd_signal.
    print "Control signal: " + ctrl_signal at (0, 15).
    print "Pitch adjustment: " + xfmd_signal at (0, 16).
    print "pitch target is " + pitch at (0, 17).
    wait 0.1.
}
set throttle_target to 0.

run suicideburn(100, 0).
run hoverthrust(-16).
