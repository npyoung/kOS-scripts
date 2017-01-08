// Parameters
parameter roll is 0.
parameter turn_angle is 1.
parameter compass is 90.
parameter final_ap is 80000.

// Imports
run once koslib.

// Fixed parameters
set min_throttle to 0.4.
set g to 9.81.
set glimit to 2.5.
set turn_g to 1.5.
set turn_start to 100.
set turn_rate to 1.
set frame_swap_alt to 30000.
set stage_wait to 3.

// Prepare the ship
clearscreen.

// Bounded throttle obeys G-limit and min_throttle
lock max_throttle to glimited_throttle(glimit).
set bounded_throttle to 1.
lock throttle to clip(bounded_throttle, min_throttle, max_throttle).

// Point up
lock pitch to 90 - VANG(FACING:VECTOR, UP:VECTOR).
lock steering to HEADING(compass, 90) + R(0, 0, roll).

// Launch
print "LAUNCH!".
stage.
when anyflameout() then {
    handleflameout().
    return true.
}

// Limit early acceleration
lock max_throttle to glimited_throttle(turn_g).

// Start turn
wait until ALT:RADAR > turn_start.
set turn_t to TIME:SECONDS.
print "Forcing start of turn".
until pitch < 90 - turn_angle {
    set target_angle to  (TIME:SECONDS - turn_t) * turn_rate.
    lock steering to HEADING(compass, 90 - target_angle) + R(0, 0, roll).
}

// Stabilize the turn
lock steering to heading(compass, 90 - turn_angle) + R(0, 0, roll).
wait 5.

// Go prograde
print "Initial turn done; holding prograde".
lock steering to SRFPROGRADE + R(0, 0, roll).

// Watch for switch to orbital prograde
when ALTITUDE > frame_swap_alt THEN {
    lock steering to PROGRADE + R(0, 0, roll).
    print "Swapping to orbital prograde".
}

// Switch from TWR limiting to time-to-Ap targeting
print "Leaving acceleration-targeting mode".
lock max_throttle to glimited_throttle(glimit).
print "Begin Ap targeting mode".
wait until APOAPSIS > final_ap or ship:verticalspeed < 0.
lock throttle to 0.

// Coast to Ap
set warpmode to "PHYSICS".
set warp to 4.
print "Coasting to Ap".
wait until ALTITUDE > body:atm:height.
set warpmode to "RAILS".
set warp to 4.

// Reentry
wait until ALTITUDE < body:atm:height.
print "Reentering".

// Dump ascent stage if necessary
set resource_lex to stage:resourceslex.
if resource_lex:haskey("LiquidFuel") {
    print "Dumping ascent stage".
    stage.
    wait until stage:ready.
}

lock steering to srfretrograde.
set warpmode to "PHYSICS".
set warp to 4.
wait until airspeed < 300.
stage.
wait until stage:ready.
unlock steering.
wait until airspeed < 100.
stage.
wait until ALT:RADAR < 25.
set warp to 0.
