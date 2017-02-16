// Land Soft-Chute
// Untargeted landing using chutes to slow down and rockets to soften the
// landing. Ideal for Duna.

lock steering to srfretrograde.
lock throttle to 0.

wait until altitude < 20000.
unlock steering.

wait until airspeed < 300 * 0.9.
stage.
gear on.

run softland(150, -2).
