// Points ship in a direction and waits for ship to realign.

// Parameters
parameter dir.

lock steering to dir.
wait until vdot(facing:forevector, dir:forevector) >= 0.999 and ship:angularvel:mag * constant:RadToDeg < 0.1.
