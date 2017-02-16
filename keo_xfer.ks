run once koslib.

parameter target_lng.

clearscreen.

// Constants
set r to body:radius.
set d to 2 * r.
set mu to body:mu.
set T_body to body:rotationperiod.
set pi to constant:pi.
set alt_keo to 2863334.
set sma_keo to alt_keo + r.
set T_keo to 6 * 60 * 60.

// Get transfer orbit period
set sma_xfer to (obt:semimajoraxis + sma_keo) / 2.
set T_xfer to 2 * constant:pi * sqrt(sma_xfer^3 / mu).
print "Period of transfer orbit: " + sec2timestr(T_xfer).

// How much does the planet rotate between xfer and circ burns?
set offset_angle to 360 * mod((T_xfer / 2) / T_body, 1).
print "Offset angle: " + round(offset_angle, 2).

// What angle should we burn at?
set burn_lng to normang(target_lng - 180 + offset_angle).
print "Burn longitude: " + round(burn_lng, 2).

// When will we arrive at that angle?
function lng_diff {
    parameter t.
    return abs(angdiff(body:geopositionof(positionat(ship, t)):lng, burn_lng)).
}

if lng_diff(time:seconds) < lng_diff(time:seconds + 0.01) {
    set guess to time:seconds + T_body / 2.
} else {
    set guess to time:seconds.
}

set burn_t to btls(lng_diff@, guess, 10, 0.1, 4).
print "Burning in: " + round(burn_t, 1) + "s".

// How much should we burn?
set v_init to velocityat(ship, burn_t):orbit:mag.
set v_final to sqrt(v_init^2 + (mu * (1/obt:semimajoraxis - 1/sma_xfer))).

// Create node
set nd to node(burn_t, 0, 0, v_final - v_init).
add nd.
