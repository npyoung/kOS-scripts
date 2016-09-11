// Parameters
parameter newpe.

// Imports
run once koslib.

if newpe < periapsis {
    set sign to -1.
} else {
    set sign to 1.
}

point_at(sign * normal()).

when sign * periapsis > sign * newpe  {
    lock throttle to 0.
}

lock throttle to 1.
